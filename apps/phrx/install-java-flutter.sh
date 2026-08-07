#!/bin/bash

set -e

echo "☕ Instalando Java JDK 17..."

# Atualizar pacotes
sudo apt update

# Instalar OpenJDK 17
sudo apt install openjdk-17-jdk -y

echo "🔍 Verificando instalação..."

JAVA_PATH=$(readlink -f $(which java))

if [ -z "$JAVA_PATH" ]; then
    echo "❌ Java não encontrado após instalação."
    exit 1
fi

JAVA_HOME_PATH=$(dirname $(dirname "$JAVA_PATH"))

echo "✅ Java encontrado:"
echo "$JAVA_PATH"

echo "📌 JAVA_HOME:"
echo "$JAVA_HOME_PATH"

# Adicionar configurações no bashrc se não existirem
if ! grep -q "JAVA_HOME" ~/.bashrc; then

cat <<EOF >> ~/.bashrc

# Java Development Kit
export JAVA_HOME=$JAVA_HOME_PATH
export PATH=\$JAVA_HOME/bin:\$PATH
EOF

echo "✅ JAVA_HOME adicionado ao ~/.bashrc"

else

echo "ℹ️ JAVA_HOME já existe no ~/.bashrc"

fi


# Aplicar configuração na sessão atual
export JAVA_HOME=$JAVA_HOME_PATH
export PATH=$JAVA_HOME/bin:$PATH


echo ""
echo "================================="
echo "☕ Java configurado com sucesso"
echo "================================="

java -version

echo ""
echo "JAVA_HOME:"
echo $JAVA_HOME

echo ""
echo "🚀 Próximo passo:"
echo "Execute:"
echo "source ~/.bashrc"
echo ""
echo "Depois:"
echo "flutter doctor -v"
