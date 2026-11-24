#
# Libraries: pyserial, numpy, matplotlib, scipy
#
# L'UART envoie 1 echantillon par byte (8 bits bruts), sans ASCII ni retour a la ligne :
# l'acquisition se fait donc par bytes bruts (ser.read), PAS readline() + int().

import serial
import numpy as np
import matplotlib.pyplot as plt
from scipy import signal
from scipy.fft import fft, fftfreq
import time

# Configuration
PORT = 'COM26'        # adapter selon OS
BAUD = 115200
FS_NOM = 1000         # frequence nominale d'echantillonnage (start_gen : FREQ = 1000)
DURATION = 0.090        # secondes d'acquisition

# Acquisition via UART (bytes bruts : 1 echantillon par byte)
print(f"Lecture {DURATION}s sur {PORT} a {BAUD} bauds...")
ser = serial.Serial(PORT, BAUD, timeout=0.01)
ser.reset_input_buffer()
time.sleep(0.2)            # laisser le flux se stabiliser
ser.reset_input_buffer()   # vider le retro-caisson pour que la fenetre soit propre

buf = bytearray()
t0 = time.time()
while time.time() - t0 < DURATION:
    buf += ser.read(64)
ser.close()

samples = np.frombuffer(bytes(buf), dtype=np.uint8).astype(np.float64)
N = len(samples)
print(f"Recu {N} echantillons")

if N < 64:
    raise SystemExit(f"ERREUR : trop peu d'echantillons ({N}) - verifier le port COM et le cable USB")

# Taux d'echantillonnage mesure (plus fiable que la valeur nominale)
FS = N / DURATION
print(f"Taux mesure : {FS:.0f} ech/s")

# Statistiques de base 
mean_val = np.mean(samples)
std_val  = np.std(samples)
min_val  = np.min(samples)
max_val  = np.max(samples)
plage    = max_val - min_val
N_eff    = np.log2(plage + 1) if plage > 0 else 1
SNR_mes  = 20 * np.log10(mean_val / std_val) if std_val > 0 else 0

print(f"min : {min_val:.1f}")
print(f"max: {max_val:.1f}")
print(f"Moyenne : {mean_val:.1f}")
print(f"Ecart-type : {std_val:.1f}")
print(f"Plage : {min_val:.0f} - {max_val:.0f} ({plage})")
print(f"Bits effectifs : {N_eff:.1f}")
print(f"SNR mesure : {SNR_mes:.1f} dB")
print(f"SNR theorique (8b) : {6.02*8+1.76:.1f} dB")

# FFT (amplitude en dB relative au pic principal)
Y = fft(samples - mean_val)
Y_mag = 20 * np.log10(np.abs(Y[:N//2]) + 1e-12)
Y_mag -= Y_mag.max()
freqs = fftfreq(N, 1/FS)[:N//2]

plt.figure(figsize=(10, 6))
plt.plot(freqs/1000, Y_mag)
plt.xlabel('Frequence (kHz)')
plt.ylabel('Amplitude (dB, relative au pic)')
plt.title('Spectre du signal capteur')
plt.grid(alpha=0.3)
plt.axvline(0.050, color='r', linestyle='--', alpha=0.5, label='50 Hz')
plt.legend()
plt.tight_layout()
plt.savefig('spectre_capteur.pdf')
plt.show()

# Detection des raies harmoniques (pics a moins de 20 dB du principal)
peaks, _ = signal.find_peaks(Y_mag, height=-20, distance=max(5, N // 40))
print("\nRaies principales :")
for p in peaks:
    if freqs[p] < 1000:
        print(f"  {freqs[p]:.1f} Hz  ->  {Y_mag[p]:.1f} dB")

# Simulation de troncature de bits 
print("\n--- Simulation troncature ---")
for n_bits in [8, 7, 6, 5, 4, 3, 2]:
    if n_bits >= 8:
        truncated = samples.astype(np.int32)
    else:
        shift = 8 - n_bits
        truncated = (samples.astype(np.int32) >> shift) << shift
    mean_t = np.mean(truncated)
    std_t  = np.std(truncated)
    snr_t  = 20 * np.log10(mean_t / std_t) if std_t > 0 else float('nan')
    print(f"  {n_bits} bits : sigma = {std_t:.1f}, SNR ~ {snr_t:.1f} dB")

# Calibration du seuil de decision 
# A faire : 2 acquisitions separees (dark + light)
# Placeholder pour la seance :
# dark_samples  = np.array([...])   # charger depuis fichier ou 2e acquisition
# light_samples = np.array([...])
# seuil = (np.mean(dark_samples) + np.mean(light_samples)) / 2
# accuracy = np.sum(light_samples > seuil) / len(light_samples)