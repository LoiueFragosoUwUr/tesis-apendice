import matplotlib.pyplot as plt
import numpy as np

def triangular(x, a, b, c):
    return np.maximum(np.minimum((x - a) / (b - a), (c - x) / (c - b)), 0)

x = np.linspace(0, 10, 200)

LA = [triangular(val, 0, 0, 3) for val in x]
MA = [triangular(val, 3, 5, 7) for val in x]
IA = [triangular(val, 7, 10, 10) for val in x]

plt.plot(x, LA, label='LA (Bajo)')
plt.plot(x, MA, label='MA (Medio)')
plt.plot(x, IA, label='IA (Alto)')
plt.title('Funciones de Membresía para Gusto Dulce')
plt.xlabel('Valor de Gdulce')
plt.ylabel('Pertenencia Difusa (mu)')
plt.legend()
plt.grid(True)
plt.show()
