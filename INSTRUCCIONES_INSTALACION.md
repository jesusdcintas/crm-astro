# 🚀 Instrucciones de Instalación y Configuración del CRM

## 📋 Requisitos Previos

- Node.js 18+ instalado
- Cuenta de Supabase (gratuita)
- Git (opcional, para clonar el repositorio)

## 🔧 Configuración del Proyecto

### 1. Configuración de Supabase

#### 1.1. Crear un proyecto en Supabase
1. Accede a [https://supabase.com](https://supabase.com)
2. Crea una cuenta o inicia sesión
3. Crea un nuevo proyecto
4. Guarda las credenciales que se generan (URL y API Key)

#### 1.2. Ejecutar el script de base de datos
1. En tu proyecto de Supabase, ve a **SQL Editor**
2. Crea una nueva query
3. Copia y pega el contenido completo del archivo `crm-complete-setup.sql`
4. Ejecuta el script (botón "Run" o Ctrl/Cmd + Enter)

Este script creará:
- ✅ 15 tablas necesarias para el CRM
- ✅ Triggers automáticos (creación de perfiles)
- ✅ Funciones de seguridad (is_admin)
- ✅ Políticas RLS (Row Level Security)
- ✅ Datos de prueba (clientes, productos, licencias, pagos)
- ✅ Vistas útiles (resúmenes y alertas)

#### 1.3. Crear usuarios de prueba

**IMPORTANTE:** Los usuarios se crean desde Supabase, no desde la aplicación.

1. En Supabase, ve a **Authentication** → **Users**
2. Haz clic en **Add user** → **Create new user**
3. Crea al menos 2 usuarios:

**Usuario Administrador:**
```
Email: admin@crm.com
Password: Admin123456
Confirm password: Admin123456
```

Después de crear el usuario:
- Haz clic en los tres puntos (⋮) del usuario
- Selecciona **Edit user**
- En **User Metadata (raw JSON)**, añade:
```json
{
  "full_name": "Administrador",
  "role": "admin"
}
```
- Guarda los cambios

**Usuario Staff:**
```
Email: staff@crm.com
Password: Staff123456
Confirm password: Staff123456
```

Después de crear el usuario:
- Haz clic en los tres puntos (⋮) del usuario
- Selecciona **Edit user**
- En **User Metadata (raw JSON)**, añade:
```json
{
  "full_name": "Empleado",
  "role": "staff"
}
```
- Guarda los cambios

**Confirmación de Email:**
- Por defecto, Supabase requiere confirmación de email
- Para testing, puedes:
  - Opción 1: Ir a **Authentication** → **Email Templates** → Desactivar confirmación
  - Opción 2: Hacer clic en los tres puntos del usuario → **Confirm email** para confirmar manualmente

### 2. Configuración del Proyecto

#### 2.1. Variables de entorno
1. En la raíz del proyecto `nasty-neptune`, crea un archivo `.env`
2. Añade las siguientes variables con tus credenciales de Supabase:

```env
# Supabase Configuration
PUBLIC_SUPABASE_URL=https://tu-proyecto.supabase.co
PUBLIC_SUPABASE_ANON_KEY=tu-anon-key-aqui

# Opcional: Configuración de desarrollo
NODE_ENV=development
```

**¿Dónde encontrar estas credenciales?**
- Ve a tu proyecto en Supabase
- Clic en el icono de engranaje (Settings) → **API**
- Copia:
  - `Project URL` → `PUBLIC_SUPABASE_URL`
  - `anon public` key → `PUBLIC_SUPABASE_ANON_KEY`

#### 2.2. Instalación de dependencias
```bash
cd nasty-neptune
npm install
```

#### 2.3. Iniciar el servidor de desarrollo
```bash
npm run dev
```

La aplicación estará disponible en `http://localhost:4321`

## 🧪 Probar la Aplicación

### Login
1. Accede a `http://localhost:4321/auth/login`
2. Usa las credenciales creadas en Supabase:
   - **Admin:** admin@crm.com / Admin123456
   - **Staff:** staff@crm.com / Staff123456

### Diferencias entre roles

**👨‍💼 Admin (admin@crm.com):**
- ✅ Ver todos los datos
- ✅ Crear clientes
- ✅ Editar clientes
- ✅ Eliminar clientes
- ✅ Gestionar productos
- ✅ Gestionar licencias
- ✅ Ver y crear pagos
- ✅ Acceso completo al dashboard

**👤 Staff (staff@crm.com):**
- ✅ Ver todos los datos
- ❌ NO puede crear
- ❌ NO puede editar
- ❌ NO puede eliminar
- Solo lectura en todo el sistema

### Funcionalidades a probar

1. **Dashboard** (`/dashboard`)
   - Visualización de estadísticas
   - Gráficos de ingresos mensuales
   - Acciones rápidas (solo visible para admin)
   - Modo oscuro/claro (botón en la esquina superior derecha)

2. **Clientes** (`/customers`)
   - Lista de clientes con filtros
   - Crear nuevo cliente (solo admin)
   - Ver detalles de cliente
   - Editar cliente (solo admin)

3. **Productos** (`/products`)
   - Catálogo de productos
   - Detalles de precios (pago único vs suscripción)

4. **Licencias** (`/licenses`)
   - Licencias activas/inactivas/expiradas
   - Asignación de licencias a clientes (solo admin)
   - Notificaciones de expiración

## 📊 Datos de Prueba Incluidos

El script `crm-complete-setup.sql` incluye:

- **10 clientes** de prueba (empresas ficticias)
- **6 productos** (CRM Básico, Profesional, Enterprise, Módulos)
- **10 licencias** (diferentes tipos y estados)
- **18 pagos** (histórico de julio a diciembre 2025)
- **5 contactos** asociados a clientes
- **6 tags** con colores (VIP, Nuevo Cliente, etc.)
- **3 interacciones** registradas
- **4 tareas** pendientes

## 🔒 Seguridad Implementada

- **RLS (Row Level Security):** Todas las tablas protegidas
- **Cookies HTTPOnly:** Tokens de sesión seguros
- **Middleware:** Protección de rutas privadas
- **Roles:** Admin tiene permisos completos, Staff solo lectura
- **Triggers:** Creación automática de perfiles al registrar usuarios

## 📚 Documentación Adicional

Para más detalles sobre la arquitectura y funcionamiento:
- **DOCUMENTACION.md**: Explicación completa del sistema de autenticación y modelo de datos
- **crm-complete-setup.sql**: Script de base de datos comentado

## ❓ Solución de Problemas

### Error: "Invalid API key"
- Verifica que las variables en `.env` sean correctas
- Asegúrate de haber copiado la `anon public` key, no la `service_role` key

### Error: "Failed to fetch user"
- Confirma que el script SQL se ejecutó completamente
- Verifica que la tabla `profiles` existe en Supabase

### No puedo crear/editar/eliminar
- Si estás logueado como **staff**, esto es normal (solo lectura)
- Usa la cuenta de **admin** para operaciones de escritura

### El usuario no aparece en la tabla profiles
- El trigger `handle_new_user()` debería crear el perfil automáticamente
- Si no funciona, verifica que el trigger esté activo en Supabase (SQL Editor → Database → Triggers)

### Error de CORS
- Asegúrate de estar accediendo a `http://localhost:4321`
- En Supabase, ve a **Settings** → **API** → **URL Configuration** y verifica que `http://localhost:4321` esté permitido

## 📧 Contacto

Para cualquier duda o problema durante la prueba, incluye:
- Mensaje de error completo (si aplica)
- Capturas de pantalla
- Usuario utilizado (admin o staff)

---

**¡El sistema está listo para probar!** 🎉

Recuerda que este es un entorno de desarrollo con datos de prueba. Los usuarios se gestionan exclusivamente desde Supabase Authentication.
