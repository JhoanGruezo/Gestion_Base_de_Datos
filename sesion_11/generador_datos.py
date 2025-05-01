import psycopg2 # type: ignore
import threading
import time
import random
from datetime import datetime
import logging
from sqlalchemy import create_engine, Column, Integer, String, DECIMAL, ForeignKey, TIMESTAMP # type: ignore
from sqlalchemy.ext.declarative import declarative_base # type: ignore
from sqlalchemy.orm import sessionmaker # type: ignore

# Configuración de logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler("banco.log"),  # Guarda los logs en un archivo
        logging.StreamHandler(),  # También los muestra en la consola
    ],
)

# Configuración de SQLAlchemy
# Cambiada la cadena de conexión para usar el nombre del servicio 'db' de Docker Compose
engine = create_engine("postgresql://mi_usuario:mi_clave@localhost:5432/banco")

Base = declarative_base()
Session = sessionmaker(bind=engine)

# Definición de los modelos de las tablas
class Cuenta(Base):
    __tablename__ = "cuentas"
    id_cuenta = Column(Integer, primary_key=True)
    nombre_cliente = Column(String)
    saldo = Column(DECIMAL)

class Transaccion(Base):
    __tablename__ = "transacciones"
    id_transaccion = Column(Integer, primary_key=True)
    id_cuenta = Column(Integer, ForeignKey("cuentas.id_cuenta"))
    tipo_transaccion = Column(String)
    monto = Column(DECIMAL)
    fecha_transaccion = Column(TIMESTAMP)

def generar_datos(tiempo_ejecucion):
    """
    Genera datos simulados de cuentas y transacciones e inserta en la base de datos usando SQLAlchemy.
    """
    inicio_tiempo = time.time()
    session = Session()
    logging.info("Hilo de generación de datos iniciado.")

    # Lista para almacenar IDs de cuentas existentes para transacciones más realistas
    cuentas_existentes = []

    while time.time() - inicio_tiempo < tiempo_ejecucion:
        try:
            # Decidir si crear una nueva cuenta o usar una existente para la transacción
            if not cuentas_existentes or random.random() < 0.3: # Probabilidad de crear una nueva cuenta
                # Generar datos de la cuenta.
                nombre_cliente = f"Cliente {random.randint(101, 10000)}" # Rango extendido
                saldo = round(random.uniform(1000, 10000), 2)

                # Crear objeto Cuenta e insertar en la base de datos.
                nueva_cuenta = Cuenta(nombre_cliente=nombre_cliente, saldo=saldo)
                session.add(nueva_cuenta)
                session.flush()  # Para obtener el id_cuenta generado
                id_cuenta_para_transaccion = nueva_cuenta.id_cuenta
                cuentas_existentes.append(id_cuenta_para_transaccion) # Añadir a la lista
                logging.info(f"Nueva cuenta creada con ID: {id_cuenta_para_transaccion}")
            else:
                # Usar una cuenta existente al azar
                id_cuenta_para_transaccion = random.choice(cuentas_existentes)
                logging.info(f"Usando cuenta existente con ID: {id_cuenta_para_transaccion}")


            # Generar datos de la transacción.
            tipo_transaccion = random.choice(["deposito", "retiro"])
            monto = round(random.uniform(100, 1000), 2)
            fecha_transaccion = datetime.now()

            # Crear objeto Transaccion e insertar.
            nueva_transaccion = Transaccion(
                id_cuenta=id_cuenta_para_transaccion,
                tipo_transaccion=tipo_transaccion,
                monto=monto,
                fecha_transaccion=fecha_transaccion,
            )
            session.add(nueva_transaccion)

            # Opcional: Actualizar el saldo de la cuenta (requiere permiso UPDATE)
            # cuenta_a_actualizar = session.query(Cuenta).filter_by(id_cuenta=id_cuenta_para_transaccion).first()
            # if tipo_transaccion == 'deposito':
            #     cuenta_a_actualizar.saldo += monto
            # else:
            #     cuenta_a_actualizar.saldo -= monto # Considerar manejo de saldo insuficiente

            session.commit() # Realizar commit después de cada transacción (se podría optimizar con bulk insert)

            logging.info(f"Datos insertados: Transacción {tipo_transaccion} - {monto} para Cuenta {id_cuenta_para_transaccion}")

            time.sleep(2)  # Esperar 2 segundos.

        except Exception as e:
            logging.error(f"Error al insertar datos: {e}")
            session.rollback() # Revertir cambios en caso de error

    session.close()
    logging.info("Hilo de generación de datos finalizado.")

def main():
    """
    Función principal para iniciar la generación de datos.
    """
    try:
        tiempo_ejecucion_str = input("Ingrese el tiempo de ejecución en segundos: ")
        tiempo_ejecucion = int(tiempo_ejecucion_str)

        # Crear las tablas si no existen (útil si no se usa init.sql o se ejecuta el script por separado)
        # Base.metadata.create_all(engine)
        # logging.info("Tablas verificadas/creadas.")

        # Crear y ejecutar el hilo para la generación de datos.
        hilo_generador = threading.Thread(target=generar_datos, args=(tiempo_ejecucion,))
        hilo_generador.start()
        hilo_generador.join()  # Esperar a que el hilo termine.

    except ValueError:
        logging.error("Entrada inválida. Por favor, ingrese un número entero para el tiempo de ejecución.")
    except Exception as e:
        logging.error(f"Error: {e}")

if __name__ == "__main__":
    main()