"""Stable MLEM-style reconstruction inspired by iritative.m.

The original script divides by (forward_projection * 0.0001), likely a
mistake. The normalized MLEM ratio below corrects that mathematical issue.
This is NOT a bit-for-bit port of the original MATLAB reconstruction.
"""
from pathlib import Path
import argparse
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from skimage.data import shepp_logan_phantom
from skimage.transform import radon, iradon, resize

def main():
    p = argparse.ArgumentParser()
    p.add_argument('--output', type=Path, default=Path('results/iterative'))
    p.add_argument('--iterations', type=int, default=20)
    p.add_argument('--size', type=int, default=120)
    args = p.parse_args()
    if args.iterations < 1 or args.size < 8:
        p.error('--iterations must be >= 1 and --size must be >= 8')
    args.output.mkdir(parents=True, exist_ok=True)
    truth = resize(shepp_logan_phantom(), (args.size, args.size), anti_aliasing=True)
    angles = np.arange(1, 101, dtype=float)
    measurements = radon(truth, theta=angles, circle=False)
    rec = np.ones_like(truth)
    # skimage's iradon(..., filter_name=None) is an unfiltered backprojection.
    def backproject(s):
        return iradon(s, theta=angles, filter_name=None, circle=False, output_size=args.size)
    sensitivity = backproject(np.ones_like(measurements))
    eps = 1e-10
    errors = []
    for iteration in range(1, args.iterations + 1):
        estimated = radon(rec, theta=angles, circle=False)
        ratio = measurements / np.maximum(estimated, eps)
        correction = backproject(ratio)
        rec *= correction / np.maximum(sensitivity, eps)
        rec = np.maximum(rec, 0.0)
        errors.append(float(np.sqrt(np.mean((rec - truth) ** 2))))
        if iteration in (1, 5, 10, 20) or iteration == args.iterations:
            np.save(args.output / f'iteration_{iteration:03}.npy', rec)
    np.save(args.output / 'reconstruction.npy', rec)
    fig, ax = plt.subplots(1, 3, figsize=(11, 4))
    ax[0].imshow(truth, cmap='gray', vmin=0, vmax=1); ax[0].set_title('Original')
    ax[1].imshow(measurements, cmap='hot', aspect='auto'); ax[1].set_title('Measured sinogram')
    ax[2].imshow(rec, cmap='gray', vmin=0, vmax=1); ax[2].set_title(f'Iterative ({args.iterations} iterations)')
    for a in ax: a.axis('off')
    fig.tight_layout(); fig.savefig(args.output / 'iterative_reconstruction.png', dpi=170); plt.close(fig)
    fig, ax = plt.subplots()
    ax.plot(np.arange(1, len(errors)+1), errors)
    ax.set(xlabel='Iteration', ylabel='RMSE vs original phantom', title='Reconstruction convergence')
    fig.tight_layout(); fig.savefig(args.output / 'convergence.png', dpi=170); plt.close(fig)
    print('Saved iterative reconstruction to:', args.output, '; final RMSE:', errors[-1])

if __name__ == '__main__':
    main()
