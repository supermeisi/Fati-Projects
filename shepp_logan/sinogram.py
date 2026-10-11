"""Free Python replacement for sinogram.m."""
from pathlib import Path
import argparse
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from skimage.data import shepp_logan_phantom
from skimage.transform import radon, resize

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', type=Path, default=Path('results/sinogram'))
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    phantom = resize(shepp_logan_phantom(), (256, 256), anti_aliasing=True)
    plt.imsave(args.output / 'phantom.png', phantom, cmap='gray')
    for step in (10, 5, 2):
        angles = np.arange(0, 180, step)
        sinogram = radon(phantom, theta=angles, circle=False)
        np.save(args.output / f'sinogram_{step}deg.npy', sinogram)
        fig, ax = plt.subplots(figsize=(8, 5))
        im = ax.imshow(sinogram, extent=(angles[0], angles[-1], sinogram.shape[0], 0), aspect='auto', cmap='hot')
        ax.set(xlabel='Angle (degrees)', ylabel='Detector pixel', title=f'Sinogram ({step}°)')
        fig.colorbar(im, ax=ax)
        fig.tight_layout()
        fig.savefig(args.output / f'sinogram_{step}deg.png', dpi=170)
        plt.close(fig)
    print('Saved sinograms to:', args.output)

if __name__ == '__main__':
    main()
