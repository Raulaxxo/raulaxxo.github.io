#!/bin/bash

# Script de configuración para el portafolio con Docker y Nginx

echo "🔧 Configurando el entorno para tu portafolio..."

# Crear la estructura de directorios
mkdir -p nginx html

# Verificar si Docker está instalado
if ! command -v docker &> /dev/null; then
    echo "❌ Docker no está instalado. Por favor, instala Docker primero."
    exit 1
fi

# Verificar si Docker Compose está instalado
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose no está instalado. Por favor, instálalo primero."
    exit 1
fi

# Crear la configuración de Nginx corregida
cat << EOF > nginx/nginx.conf
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Configuración de log
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    # Optimizaciones generales
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    # Configuración de compresión
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private auth;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
    gzip_disable "MSIE [1-6]\.";

    # Configuración de seguridad
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    # Configuración del servidor HTTP
    server {
        listen 80;
        server_name localhost;
        root /usr/share/nginx/html;
        index index.html;

        # Configuración para archivos estáticos
        location / {
            try_files \$uri \$uri/ /index.html;
            # Configuración de caché para archivos estáticos
            location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
                expires 1y;
                add_header Cache-Control "public, immutable";
            }
        }

        # Prevención de acceso a archivos ocultos
        location ~ /\. {
            deny all;
        }
    }
}
EOF

# Preguntar si quiere configurar SSL
read -p "¿Deseas configurar SSL con certificado propio? (s/n): " setup_ssl
if [[ $setup_ssl == "s" || $setup_ssl == "S" ]]; then
    mkdir -p nginx/ssl
    echo "📍 Por favor, coloca tus certificados SSL en la carpeta nginx/ssl/"
    echo "   - Nombre del certificado: tu_dominio.crt"
    echo "   - Nombre de la clave privada: tu_dominio.key"
    
    # Agregar configuración SSL al archivo nginx.conf (comentada por defecto)
    cat << EOF >> nginx/nginx.conf

    # Configuración SSL (descomenta y ajusta cuando tengas los certificados)
    # server {
    #     listen 443 ssl http2;
    #     server_name localhost;
    #     
    #     ssl_certificate /etc/nginx/ssl/tu_dominio.crt;
    #     ssl_certificate_key /etc/nginx/ssl/tu_dominio.key;
    #     
    #     ssl_protocols TLSv1.2 TLSv1.3;
    #     ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    #     ssl_prefer_server_ciphers off;
    #     
    #     root /usr/share/nginx/html;
    #     index index.html;
    #
    #     location / {
    #         try_files \$uri \$uri/ /index.html;
    #     }
    # }
EOF
    
    echo "ℹ️  Configuración SSL añadida (comentada). Cuando tengas los certificados:"
    echo "   1. Descomenta la sección SSL en nginx/nginx.conf"
    echo "   2. Ajusta los nombres de los archivos de certificado"
    echo "   3. Reinicia el contenedor: docker-compose restart"
fi

# Crear docker-compose.yml
cat << EOF > docker-compose.yml
version: '3.8'

services:
  nginx:
    image: nginx:alpine
    container_name: portfolio-nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./html:/usr/share/nginx/html
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./nginx/ssl:/etc/nginx/ssl
    restart: unless-stopped
    networks:
      - portfolio-network

networks:
  portfolio-network:
    driver: bridge
EOF

# Crear un archivo HTML de ejemplo si no existe
if [ ! -f html/index.html ]; then
    cat << EOF > html/index.html
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mi Portafolio Profesional</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 0;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            background-color: #f0f0f0;
        }
        .container {
            text-align: center;
            padding: 2rem;
            background: white;
            border-radius: 10px;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #2c3e50;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Mi Portafolio Profesional</h1>
        <p>¡Bienvenido a mi portafolio! Reemplaza este contenido con tu HTML.</p>
        <p>Coloca tu archivo HTML en la carpeta <code>html/</code> con el nombre <code>index.html</code></p>
    </div>
</body>
</html>
EOF
    echo "✅ Archivo HTML de ejemplo creado en html/index.html"
fi

echo "✅ Configuración completada!"
echo ""
echo "📝 Pasos siguientes:"
echo "   1. Coloca tu archivo HTML en la carpeta 'html/'"
echo "   2. Ejecuta: docker-compose up -d"
echo "   3. Abre tu navegador en: http://localhost"
echo ""
echo "🛠️  Comandos útiles:"
echo "   - Iniciar: docker-compose up -d"
echo "   - Detener: docker-compose down"
echo "   - Ver logs: docker-compose logs"