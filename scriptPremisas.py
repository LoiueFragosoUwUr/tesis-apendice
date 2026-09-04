from itertools import product

# Definir conjuntos difusos (etiquetas) para cada entrada
Gdulce = ["LD", "MD", "HD"]      # Gusto Dulce: Bajo, Medio, Alto
Gsalado = ["LS", "MS", "HS"]     # Gusto Salado: Bajo, Medio, Alto
Gamargo = ["LA", "MA", "HA"]     # Gusto Amargo: Bajo, Medio, Alto
Rmedica = ["LR", "MR", "HR"]        # Riesgo Médico: Seguro, Moderado, Riesgoso
Iglucemico = ["LI", "MI", "HI"]  # Índice Glucémico: Bajo, Medio, Alto

# Crear combinaciones posibles de entradas
combinaciones = product(Gdulce, Gsalado, Gamargo, Rmedica, Iglucemico)

# Crear y mostrar las premisas
print("PREMISAS DEL SISTEMA DIFUSO MAMDANI\n")
for i, (dulce, salado, amargo, riesgo, ig) in enumerate(combinaciones, start=1):
    print("\item "f"Regla {i}: \si Gd ES {dulce} \y Gs ES {salado} \y Ga ES {amargo} \y Rm ES {riesgo} \y Ig ES {ig} \\then Ra\n")
