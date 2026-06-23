# 
# 1. Usando la imagen que sugiere  NVIDIA "docker pull nvcr.io/nvidia/cuquantum-appliance:24.03-x86_64"
FROM nvcr.io/nvidia/cuquantum-appliance:24.03-x86_64

# 2. Configurar entorno para evitar pausas en la instalación
ENV DEBIAN_FRONTEND=noninteractive

# 3. Pasar a root,esto se hace debido a que la imagen original nos asigna un usuario sin privilegios 
USER root 
# 4. Instalar herramientas adicionales 
RUN apt-get update && apt-get install -y --no-install-recommends \
    gdb \
    htop \
    nano \
    tmux \
    nvtop \
    clang-format \
    && rm -rf /var/lib/apt/lists/*
    
RUN pip3 install nvitop
# OPCIONAL.
# Despues de probarlo se opto mejor por escribir las rutas directamente al momento de ejecutar 
# esto devido a que complica la ejecucion otras herramientas  
# # 5. Configuracion del path ,para facilitar la compilacion y ejecucion
# ENV CUQUANTUM_ENV_PATH=/opt/conda/envs/cuquantum-24.03

# ENV CPATH=${CUQUANTUM_ENV_PATH}/include:${CPATH}
# ENV LIBRARY_PATH=${CUQUANTUM_ENV_PATH}/lib:${LIBRARY_PATH}
# ENV LD_LIBRARY_PATH=${CUQUANTUM_ENV_PATH}/lib:${LD_LIBRARY_PATH}


# 6. Establecer el directorio de trabajo por defecto
WORKDIR /workspace
COPY . /workspace

# 7. Comando por defecto
CMD ["/bin/bash"]