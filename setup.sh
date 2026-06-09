#!/bin/bash
# TuProfe iOS - Setup Script
# Requiere: Xcode 15+, Homebrew, xcodegen

set -e

echo "🚀 Configurando TuProfe iOS..."

# 1. Instalar xcodegen si no está instalado
if ! command -v xcodegen &> /dev/null; then
    echo "📦 Instalando xcodegen..."
    brew install xcodegen
fi

# 2. Generar el proyecto Xcode
echo "🔧 Generando proyecto Xcode..."
xcodegen generate

echo ""
echo "✅ Proyecto generado: TuProfeIOS.xcodeproj"
echo ""
echo "⚠️  PASOS OBLIGATORIOS antes de compilar:"
echo ""
echo "1. FIREBASE - GoogleService-Info.plist:"
echo "   → Ve a console.firebase.google.com"
echo "   → Agrega una app iOS con Bundle ID: com.tuprofe.ios"
echo "   → Descarga GoogleService-Info.plist"
echo "   → Reemplaza TuProfeIOS/Supporting/GoogleService-Info.plist"
echo ""
echo "2. GROQ API Key:"
echo "   → En Xcode: Project → TuProfeIOS → Build Settings"
echo "   → Busca 'User-Defined' y agrega: GROQ_API_KEY = tu_api_key"
echo "   → O edita el Info.plist directamente"
echo ""
echo "3. BACKEND URL:"
echo "   → Abre TuProfeIOS/Data/Services/APIService.swift"
echo "   → Cambia baseURL por tu URL real del backend"
echo ""
echo "4. FUENTES PERSONALIZADAS (opcional):"
echo "   → Agrega BebasNeue-Regular.ttf y Montserrat-Regular.ttf"
echo "   → a TuProfeIOS/Resources/Fonts/"
echo "   → Declara en Info.plist bajo 'Fonts provided by application'"
echo ""
echo "5. Abre el proyecto:"
echo "   open TuProfeIOS.xcodeproj"