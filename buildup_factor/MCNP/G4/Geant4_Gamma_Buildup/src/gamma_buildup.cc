// Geant4 11.x - corrected 3-layer cylindrical gamma shielding simulation.
// This is a *surface photon fluence* measurement on the OUTER LATERAL surface.
// Only outward crossings from water into vacuum are scored. One photon primary
// is generated per event, with isotropic direction.
//
// B_phi = Phi_all / Phi_uncollided
// B_E   = (sum E*Phi)_all / (sum E*Phi)_uncollided
//
// Geant4 has to be installed to compile and run this program.

#include "G4DecayPhysics.hh"
#include "G4EmLivermorePhysics.hh"
#include "G4Event.hh"
#include "G4Gamma.hh"
#include "G4LogicalVolume.hh"
#include "G4Material.hh"
#include "G4NistManager.hh"
#include "G4ParticleGun.hh"
#include "G4PVPlacement.hh"
#include "G4PhysicalConstants.hh"
#include "G4Run.hh"
#include "G4RunManager.hh"
#include "G4Step.hh"
#include "G4SystemOfUnits.hh"
#include "G4Tubs.hh"
#include "G4VModularPhysicsList.hh"
#include "G4VUserDetectorConstruction.hh"
#include "G4VUserPrimaryGeneratorAction.hh"
#include "G4UserEventAction.hh"
#include "G4UserRunAction.hh"
#include "G4UserSteppingAction.hh"
#include "G4VSolid.hh"
#include "G4VProcess.hh"
#include "G4VPhysicalVolume.hh"
#include "G4ThreeVector.hh"
#include "Randomize.hh"

#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <limits>
#include <stdexcept>
#include <string>

namespace {

struct Config {
    double energyMeV = 2.0;
    double leadCm = 1.0, ironCm = 1.0, waterCm = 1.0;
    double commonHeightCm = 30.0;
    int events = 100000;
    long seed = 12345;
    bool vacuumShield = false;  // optional analytic benchmark mode
    std::string geometry = "original"; // original or equal-height
    std::string output = "result.csv";
};

void Usage(const char *name) {
    std::cout << "Usage: " << name << " [OPTIONS]\n"
        << "  --energy-mev 0.5|1|1.5|2|2.5\n"
        << "  --lead-cm N --iron-cm N --water-cm N\n"
        << "  --geometry original|equal-height\n"
        << "  --height-cm N          (total height; equal-height geometry only; default 30)\n"
        << "  --events N             (default 100000; use 1000000 for production)\n"
        << "  --seed N               (positive integer)\n"
        << "  --vacuum-shield        (replace Pb, Fe and water with vacuum for testing)\n"
        << "  --output FILE.csv\n";
}

Config Parse(int argc, char **argv) {
    Config c;
    for (int i=1; i<argc; ++i) {
        std::string k=argv[i];
        if (k=="--help" || k=="-h") { Usage(argv[0]); std::exit(0); }
        if (k=="--vacuum-shield") { c.vacuumShield=true; continue; }
        if (i+1>=argc) throw std::runtime_error("Missing value after "+k);
        const std::string v=argv[++i];
        if      (k=="--energy-mev") c.energyMeV=std::stod(v);
        else if (k=="--lead-cm") c.leadCm=std::stod(v);
        else if (k=="--iron-cm") c.ironCm=std::stod(v);
        else if (k=="--water-cm") c.waterCm=std::stod(v);
        else if (k=="--height-cm") c.commonHeightCm=std::stod(v);
        else if (k=="--events") c.events=std::stoi(v);
        else if (k=="--seed") c.seed=std::stol(v);
        else if (k=="--output") c.output=v;
        else if (k=="--geometry") c.geometry=v;
        else throw std::runtime_error("Unknown option: "+k);
    }
    if (!std::isfinite(c.energyMeV) || c.energyMeV<=0 ||
        !std::isfinite(c.leadCm) || c.leadCm<=0 ||
        !std::isfinite(c.ironCm) || c.ironCm<=0 ||
        !std::isfinite(c.waterCm) || c.waterCm<=0 ||
        !std::isfinite(c.commonHeightCm) || c.commonHeightCm<=0 ||
        c.events<1 || c.seed<1 ||
        (c.geometry!="original" && c.geometry!="equal-height"))
        throw std::runtime_error("Invalid argument(s). Use --help.");
    return c;
}

// Original MCNP input:
//   RCC 1: r=5 cm, half-height=5 cm
//   RCC 2: r=10 cm, half-height=10 cm
//   RCC 3: r=15 cm, half-height=15 cm.
// Interprets each layer thickness as a RADIAL thickness and preserves
// half-height == cumulative outer radius in the 'original' option.
// This is an explicit assumption for the other 12 combinations.
struct Dimensions {
    double rPb=0, rFe=0, rWater=0;
    double hPb=0, hFe=0, hWater=0; // half heights in Geant4 units
};
Dimensions MakeDimensions(const Config &c) {
    Dimensions d;
    d.rPb=c.leadCm*cm;
    d.rFe=(c.leadCm+c.ironCm)*cm;
    d.rWater=(c.leadCm+c.ironCm+c.waterCm)*cm;
    if (c.geometry=="original") {
        d.hPb=d.rPb;
        d.hFe=d.rFe;
        d.hWater=d.rWater;
    } else {
        d.hPb=d.hFe=d.hWater=0.5*c.commonHeightCm*cm;
    }
    return d;
}

class Detector final : public G4VUserDetectorConstruction {
public:
    explicit Detector(const Config &c): dims_(MakeDimensions(c)), vacuumShield_(c.vacuumShield) {}
    G4VPhysicalVolume* Construct() override {
        auto *nist=G4NistManager::Instance();
        auto *vacuum=nist->FindOrBuildMaterial("G4_Galactic");
        auto *lead=nist->FindOrBuildMaterial("G4_Pb");
        auto *iron=nist->FindOrBuildMaterial("G4_Fe");
        auto *water=nist->FindOrBuildMaterial("G4_WATER");
        if (vacuumShield_) { lead=vacuum; iron=vacuum; water=vacuum; }
        const double halfWorld=std::max({100.0*cm, dims_.rWater+10*cm, dims_.hWater+10*cm});
        auto *ws=new G4Tubs("WorldSolid",0,halfWorld,halfWorld,0,twopi);
        auto *wl=new G4LogicalVolume(ws,vacuum,"WorldLV");
        world_=new G4PVPlacement(nullptr,{},wl,"WorldPV",nullptr,false,0);
        auto *sWater=new G4Tubs("WaterCylinder",0,dims_.rWater,dims_.hWater,0,twopi);
        auto *lWater=new G4LogicalVolume(sWater,water,"WaterLV");
        water_=new G4PVPlacement(nullptr,{},lWater,"WaterPV",wl,false,0);
        auto *sIron=new G4Tubs("IronCylinder",0,dims_.rFe,dims_.hFe,0,twopi);
        auto *lIron=new G4LogicalVolume(sIron,iron,"IronLV");
        new G4PVPlacement(nullptr,{},lIron,"IronPV",lWater,false,0);
        auto *sLead=new G4Tubs("LeadCylinder",0,dims_.rPb,dims_.hPb,0,twopi);
        auto *lLead=new G4LogicalVolume(sLead,lead,"LeadLV");
        new G4PVPlacement(nullptr,{},lLead,"LeadPV",lIron,false,0);
        // Nested placement represents original MCNP cells: lead core,
        // iron envelope minus lead, water envelope minus iron.
        return world_;
    }
    G4VPhysicalVolume* Water() const {return water_;}
    G4VPhysicalVolume* World() const {return world_;}
    const Dimensions& Dims() const {return dims_;}
private:
    Dimensions dims_;
    bool vacuumShield_;
    G4VPhysicalVolume *world_=nullptr, *water_=nullptr;
};

class Physics final : public G4VModularPhysicsList {
public:
    Physics() {
        SetVerboseLevel(0);
        RegisterPhysics(new G4EmLivermorePhysics());
        RegisterPhysics(new G4DecayPhysics());
        SetDefaultCutValue(0.01*mm);  // record for reproducibility
    }
};

class Primary final : public G4VUserPrimaryGeneratorAction {
public:
    explicit Primary(const Config &c) {
        gun_=new G4ParticleGun(1);
        gun_->SetParticleDefinition(G4Gamma::GammaDefinition());
        gun_->SetParticlePosition(G4ThreeVector(0,0,0));
        gun_->SetParticleEnergy(c.energyMeV*MeV);
    }
    ~Primary() override { delete gun_; }
    void GeneratePrimaries(G4Event *event) override {
        // Uniform in solid angle: mu=cos(theta) uniform on [-1,1].
        const double mu=2.0*G4UniformRand()-1.0;
        const double phi=twopi*G4UniformRand();
        const double sinTheta=std::sqrt(std::max(0.0,1.0-mu*mu));
        gun_->SetParticleMomentumDirection(G4ThreeVector(sinTheta*std::cos(phi),
                                                         sinTheta*std::sin(phi),mu));
        gun_->GeneratePrimaryVertex(event);
    }
private:
    G4ParticleGun *gun_;
};

struct EventTallies {
    double phiAll=0, phiDirect=0, energyPhiAll=0, energyPhiDirect=0;
    double currentAll=0, currentDirect=0;
};

struct PairMoments {
    double x=0,y=0,x2=0,y2=0,xy=0;
    void Add(double total, double direct) {
        x+=total; y+=direct;
        x2+=total*total; y2+=direct*direct; xy+=total*direct;
    }
    double Ratio() const {
        return y>0 ? x/y : std::numeric_limits<double>::quiet_NaN();
    }
    double StandardError(int n) const {
        if (n<2 || y<=0) return std::numeric_limits<double>::quiet_NaN();
        const double b=Ratio();
        // Sample variance of z(event)=x(event)-B*y(event).
        // The sample mean of z is 0 by construction. Delta method for X/Y.
        const double sumZ2=x2+b*b*y2-2*b*xy;
        const double ybar=y/n;
        const double varB=std::max(0.0,sumZ2/(n-1)) / (n*ybar*ybar);
        return std::sqrt(varB);
    }
};

class RunAction final : public G4UserRunAction {
public:
    explicit RunAction(const Config &c): cfg_(c), d_(MakeDimensions(c)) {}
    void AddEvent(const EventTallies &e) {
        phi_.Add(e.phiAll,e.phiDirect);
        energy_.Add(e.energyPhiAll,e.energyPhiDirect);
        current_.Add(e.currentAll,e.currentDirect);
    }
    void EndOfRunAction(const G4Run *r) override {
        const int n=r->GetNumberOfEvent();
        if (!n) throw std::runtime_error("Zero events simulated");
        std::ofstream o(cfg_.output);
        if (!o) throw std::runtime_error("Cannot open output: "+cfg_.output);
        o << "geometry,vacuum_shield,energy_MeV,lead_cm,iron_cm,water_cm,"
             "r_lead_cm,r_iron_cm,r_outer_cm,h_lead_cm,h_iron_cm,h_outer_cm,"
             "n_events,seed,phi_total_per_cm2_per_primary,"
             "phi_uncollided_per_cm2_per_primary,B_phi,SE_B_phi,"
             "energy_phi_total_MeV_per_cm2_per_primary,"
             "energy_phi_uncollided_MeV_per_cm2_per_primary,B_energy,SE_B_energy,"
             "lateral_outgoing_gamma_count_per_primary,"
             "lateral_uncollided_gamma_count_per_primary,B_current,SE_B_current\n";
        o << std::setprecision(12);
        o << cfg_.geometry << ',' << (cfg_.vacuumShield ? 1 : 0) << ','
          << cfg_.energyMeV << ',' << cfg_.leadCm << ','
          << cfg_.ironCm << ',' << cfg_.waterCm << ','
          << d_.rPb/cm << ',' << d_.rFe/cm << ',' << d_.rWater/cm << ','
          << 2*d_.hPb/cm << ',' << 2*d_.hFe/cm << ',' << 2*d_.hWater/cm << ','
          << n << ',' << cfg_.seed << ','
          << phi_.x/n << ',' << phi_.y/n << ',' << phi_.Ratio() << ','
          << phi_.StandardError(n) << ','
          << energy_.x/n << ',' << energy_.y/n << ',' << energy_.Ratio() << ','
          << energy_.StandardError(n) << ','
          << current_.x/n << ',' << current_.y/n << ',' << current_.Ratio() << ','
          << current_.StandardError(n) << '\n';
        std::cout << std::setprecision(6) << "Saved " << cfg_.output
                  << "  B_phi=" << phi_.Ratio()
                  << " +/- " << phi_.StandardError(n)
                  << "  B_energy=" << energy_.Ratio()
                  << " +/- " << energy_.StandardError(n) << '\n';
        if (phi_.y <= 0) std::cerr << "WARNING: No uncollided outgoing photons; "
                                          "increase --events.\n";
    }
private:
    Config cfg_;
    Dimensions d_;
    PairMoments phi_, energy_, current_;
};

class EventAction final : public G4UserEventAction {
public:
    explicit EventAction(RunAction *run): run_(run) {}
    void BeginOfEventAction(const G4Event *) override {
        e_=EventTallies{};
        primaryHasInteracted_=false;
    }
    void EndOfEventAction(const G4Event *) override {run_->AddEvent(e_);}
    void MarkPrimaryInteraction() {primaryHasInteracted_=true;}
    bool PrimaryInteracted() const {return primaryHasInteracted_;}
    void Score(double surfaceFlux, double energyMeV, double weight, bool direct) {
        e_.phiAll+=surfaceFlux;
        e_.energyPhiAll+=surfaceFlux*energyMeV;
        e_.currentAll+=weight;
        if (direct) {
            e_.phiDirect+=surfaceFlux;
            e_.energyPhiDirect+=surfaceFlux*energyMeV;
            e_.currentDirect+=weight;
        }
    }
private:
    RunAction *run_;
    EventTallies e_;
    bool primaryHasInteracted_=false;
};

class Stepping final : public G4UserSteppingAction {
public:
    Stepping(const Detector *det, EventAction *event): det_(det), event_(event) {}
    void UserSteppingAction(const G4Step *step) override {
        auto *track=step->GetTrack();
        if (track->GetParticleDefinition()!=G4Gamma::GammaDefinition()) return;
        const auto *pre=step->GetPreStepPoint();
        const auto *post=step->GetPostStepPoint();
        // IMPORTANT: detect gamma collisions by physics process, NOT an
        // energy bin. Rayleigh changes direction without changing energy.
        const auto *process=post->GetProcessDefinedStep();
        if (track->GetParentID()==0 && process) {
            const auto name=process->GetProcessName();
            if (name!="Transportation" && name!="CoupledTransportation")
                event_->MarkPrimaryInteraction();
        }
        if (post->GetStepStatus()!=fGeomBoundary ||
            pre->GetPhysicalVolume()!=det_->Water() ||
            post->GetPhysicalVolume()!=det_->World()) return;
        const auto &d=det_->Dims();
        const auto &pos=post->GetPosition();
        const double radial=std::hypot(pos.x(),pos.y());
        // Exclude the two circular end caps, keep only the lateral surface.
        if (std::abs(radial-d.rWater)>1.e-5*mm ||
            std::abs(pos.z())>=d.hWater-1.e-5*mm) return;
        const auto &dir=post->GetMomentumDirection();
        const double cosOut=(pos.x()*dir.x()+pos.y()*dir.y())/radial;
        if (!(cosOut>0)) return;
        const double areaCm2= (twopi*d.rWater*(2*d.hWater))/(cm*cm);
        const double weight=track->GetWeight();
        const double surfaceFlux=weight/(cosOut*areaCm2); // photon/cm2
        const bool direct=track->GetParentID()==0 && !event_->PrimaryInteracted();
        event_->Score(surfaceFlux, pre->GetKineticEnergy()/MeV, weight, direct);
    }
private:
    const Detector *det_;
    EventAction *event_;
};

} // namespace

int main(int argc, char **argv) {
    try {
        const Config cfg=Parse(argc,argv);
        G4Random::setTheSeed(cfg.seed);
        auto *rm=new G4RunManager(); // explicitly serial for reliable event statistics
        auto *det=new Detector(cfg);
        rm->SetUserInitialization(det);
        rm->SetUserInitialization(new Physics());
        auto *run=new RunAction(cfg);
        auto *event=new EventAction(run);
        rm->SetUserAction(new Primary(cfg));
        rm->SetUserAction(run);
        rm->SetUserAction(event);
        rm->SetUserAction(new Stepping(det,event));
        rm->Initialize();
        rm->BeamOn(cfg.events);
        delete rm;
        return 0;
    } catch(const std::exception &e) {
        std::cerr << "ERROR: " << e.what() << '\n';
        return 1;
    }
}
