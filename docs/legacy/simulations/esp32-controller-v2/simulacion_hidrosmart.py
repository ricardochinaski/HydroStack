"""
HidroSmart v2.0 — Simulador Python de la lógica de control
Ejecuta: python simulacion_hidrosmart.py
"""

import time
import random
import os

# ================================================================
# PARÁMETROS (idénticos al firmware C++)
# ================================================================
PH_SETPOINT = 6.0
PH_DEADBAND = 0.5
PH_HYST_LOW = PH_SETPOINT - PH_DEADBAND   # 5.5
PH_HYST_HIGH = PH_SETPOINT + PH_DEADBAND  # 6.5

EC_SETPOINT = 1.8
EC_DEADBAND = 0.15
EC_HYST_LOW = EC_SETPOINT - EC_DEADBAND   # 1.65
EC_HYST_HIGH = EC_SETPOINT + EC_DEADBAND  # 1.95

TIEMPO_BOMBA_NUT = 3.0   # segundos
TIEMPO_BOMBA_PH = 2.0    # segundos
WINDOW_SIZE = 15

# ================================================================
# ESTADO GLOBAL
# ================================================================
buffer_ph = []
buffer_ec = []

ph_filtrado = 7.0
ec_filtrado = 0.0

bomba_nut = False
bomba_ph = False
led = False

tiempo_fin_nut = 0
tiempo_fin_ph = 0

tiempo_total = 0.0

# ================================================================
# FILTRO DE PROMEDIO MÓVIL
# ================================================================
def filtrar(buffer, valor):
    buffer.append(valor)
    if len(buffer) > WINDOW_SIZE:
        buffer.pop(0)
    return sum(buffer) / len(buffer)

# ================================================================
# CONTROL CON HISTÉRESIS
# ================================================================
def controlar(t):
    global bomba_nut, bomba_ph, led, tiempo_fin_nut, tiempo_fin_ph

    # --- pH ---
    if ph_filtrado > PH_HYST_HIGH and not bomba_ph and tiempo_fin_ph == 0:
        bomba_ph = True
        tiempo_fin_ph = t + TIEMPO_BOMBA_PH
        print(f"[CONTROL] pH ALTO ({ph_filtrado:.2f}) -> ACTIVANDO bomba pH- por {TIEMPO_BOMBA_PH:.0f}s")
    elif ph_filtrado < PH_HYST_LOW and bomba_ph:
        bomba_ph = False
        print(f"[CONTROL] pH NORMAL ({ph_filtrado:.2f}) -> DESACTIVANDO bomba pH-")

    # --- EC (nutrientes) ---
    if ec_filtrado < EC_HYST_LOW and not bomba_nut and tiempo_fin_nut == 0:
        bomba_nut = True
        tiempo_fin_nut = t + TIEMPO_BOMBA_NUT
        print(f"[CONTROL] EC BAJO ({ec_filtrado:.3f}) -> ACTIVANDO bomba nutrientes por {TIEMPO_BOMBA_NUT:.0f}s")
    elif ec_filtrado > EC_HYST_HIGH and bomba_nut:
        bomba_nut = False
        print(f"[CONTROL] EC NORMAL ({ec_filtrado:.3f}) -> DESACTIVANDO bomba nutrientes")

    # --- LED (ciclo 6s diurno / 4s nocturno simulado) ---
    hora_simulada = (t / 3600) % 24
    led_deseado = (6 <= hora_simulada < 20)
    if led_deseado != led:
        led = led_deseado
        print(f"[CONTROL] LED {'ON (ciclo diurno)' if led else 'OFF (ciclo nocturno)'}")

# ================================================================
# TEMPORIZADORES
# ================================================================
def gestionar_timers(t):
    global bomba_nut, bomba_ph, tiempo_fin_nut, tiempo_fin_ph
    if bomba_nut and tiempo_fin_nut > 0 and t >= tiempo_fin_nut:
        bomba_nut = False
        tiempo_fin_nut = 0
        print(f"[TEMPORIZADOR] Bomba nutrientes APAGADA por tiempo")
    if bomba_ph and tiempo_fin_ph > 0 and t >= tiempo_fin_ph:
        bomba_ph = False
        tiempo_fin_ph = 0
        print(f"[TEMPORIZADOR] Bomba pH- APAGADA por tiempo")

# ================================================================
# SIMULACIÓN DE LECTURAS (emula ADC con deriva + ruido)
# ================================================================
def simular_sensores():
    global ph_filtrado, ec_filtrado

    # --- Simular pH con deriva suave y perturbaciones ---
    ph_real = 7.0 + 0.5 * (tiempo_total / 120)  # sube lentamente
    ph_real += random.gauss(0, 0.3)               # ruido
    # Si la bomba pH- está activa, el pH baja
    if bomba_ph:
        ph_real -= 0.8
    ph_real = max(0, min(14, ph_real))

    # --- Simular EC con deriva suave ---
    ec_real = 1.5 + 0.3 * (tiempo_total / 180)
    ec_real += random.gauss(0, 0.1)
    if bomba_nut:
        ec_real += 0.6
    ec_real = max(0, min(5, ec_real))

    # --- Aplicar filtro de promedio móvil ---
    adc_raw_ph = int(ph_real / 14 * 4095)
    adc_raw_ec = int(ec_real / 5 * 4095)

    ph_filtrado = filtrar(buffer_ph, adc_raw_ph) / 4095 * 14
    ec_filtrado = filtrar(buffer_ec, adc_raw_ec) / 4095 * 5

    return adc_raw_ph, adc_raw_ec

# ================================================================
# PANTALLA (simulada en consola)
# ================================================================
def mostrar_pantalla():
    os.system("cls" if os.name == "nt" else "clear")
    print("=" * 50)
    print("  HidroSmart v2.0 — MODO AUTONOMO     [SIMULACION]")
    print("=" * 50)
    print(f"  pH: {ph_filtrado:.1f}")
    print(f"  EC: {ec_filtrado:.2f} mS/cm")
    print("-" * 50)
    print(f"  NUT: {'ON ' if bomba_nut else 'OFF'}   pH-: {'ON ' if bomba_ph else 'OFF'}   LED: {'ON ' if led else 'OFF'}")
    print(f"  Tiempo: {tiempo_total:.1f}s")
    print("=" * 50)

# ================================================================
# LOG SERIAL SIMULADO
# ================================================================
def log_serial(raw_ph, raw_ec):
    volt_ph = raw_ph / 4095 * 3.3
    volt_ec = raw_ec / 4095 * 3.3
    print(f"[ADC] RAW | pH: {raw_ph} ({volt_ph:.3f} V)  |  EC: {raw_ec} ({volt_ec:.3f} V)")
    print(f"[FILTRO] SUAVIZADO | pH: {ph_filtrado:.2f}  |  EC: {ec_filtrado:.3f} mS/cm")

# ================================================================
# BUCLE PRINCIPAL (Non-blocking simulado)
# ================================================================
if __name__ == "__main__":
    t_anterior = time.time()

    print("INICIALIZANDO SISTEMA...")
    time.sleep(1)

    try:
        while True:
            ahora = time.time()
            dt = ahora - t_anterior

            if dt >= 0.2:  # cada 200ms (como el firmware real)
                t_anterior = ahora
                tiempo_total += dt

                # === MISMA ESTRUCTURA DEL LOOP EN C++ ===
                raw_ph, raw_ec = simular_sensores()
                controlar(tiempo_total)
                gestionar_timers(tiempo_total)

                if int(tiempo_total * 10) % 3 == 0:
                    log_serial(raw_ph, raw_ec)

                if int(tiempo_total * 10) % 5 == 0:
                    mostrar_pantalla()

                # Telemetría simulada cada 1s
                if int(tiempo_total) > int(tiempo_total - dt):
                    payload = f'{{"pH":{ph_filtrado:.2f},"ec":{ec_filtrado:.3f},"nut":{1 if bomba_nut else 0},"ph_pump":{1 if bomba_ph else 0},"led":{1 if led else 0}}}'
                    print(f"[IoT] {payload}")

            time.sleep(0.01)

    except KeyboardInterrupt:
        print("\nSimulacion detenida.")
