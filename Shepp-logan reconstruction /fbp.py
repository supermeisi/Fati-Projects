"""FBP and salt-and-pepper noise experiments, based on FBP.m."""
from pathlib import Path
import argparse
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from skimage.data import shepp_logan_phantom
from skimage.transform import radon, iradon, resize
from skimage.util import random_noise

def main():
    p = argparse.ArgumentParser()
    p.add_argument('--output', type=Path, default=Path('results/fbp'))
    p.add_argument('--seed', type=int, default=42)
    args = p.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    phantom = resize(shepp_logan_phantom(), (256, 256), anti_aliasing=True)
    rng = np.random.default_rng(args.seed)
    fig, ax = plt.subplots(2, 4, figsize=(14, 8))
    ax[0, 0].imshow(phantom, cmap='gray', vmin=0, vmax=1)
    ax[0, 0].set_title('Original Shepp–Logan')
    reconstructed = {}
    for col, step in enumerate((10, 5, 2), start=1):
        theta = np.arange(0, 180, step)
        sino = radon(phantom, theta=theta, circle=False)
        rec = iradon(sino, theta=theta, filter_name='ramp', circle=False, output_size=256)
        reconstructed[step] = rec
        ax[0, col].imshow(rec, cmap='gray', vmin=0, vmax=1)
        ax[0, col].set_title(f'FBP, {step}°')
        np.save(args.output / f'fbp_{step}deg.npy', rec)
    # MATLAB applied noise successively to I3, updating the reconstruction in each cycle.
    current = reconstructed[2]
    for col, amount in enumerate((0.01, 0.025, 0.05), start=1):
        noisy = random_noise(np.clip(current, 0, 1), mode='s&p', amount=amount, rng=rng)
        theta = np.arange(0, 180, 2)
        sino = radon(noisy, theta=theta, circle=False)
        current = iradon(sino, theta=theta, filter_name='ramp', circle=False, output_size=256)
        ax[1, col].imshow(current, cmap='gray', vmin=0, vmax=1)
        ax[1, col].set_title(f'FBP after S&P noise: {amount:.1%}')
        np.save(args.output / f'fbp_noise_{amount:.3f}.npy', current)
    ax[1, 0].axis('off')
    for a in ax.flat: a.axis('off')
    fig.tight_layout()
    fig.savefig(args.output / 'fbp_comparison.png', dpi=170)
    plt.close(fig)
    print('Saved FBP outputs to:', args.output)

if __name__ == '__main__':
    main()
