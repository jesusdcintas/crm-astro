-- ============================================
-- ESQUEMA DE BASE DE DATOS - MINI-CRM SOFTCONTROL
-- ============================================
-- Sistema CRM para gestión de clientes, productos y licencias
-- Empresa: SoftControl (ficticia)
-- ============================================

-- Habilitar extensión para UUIDs
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. TABLA DE PERFILES DE USUARIO
-- ============================================
-- Almacena información adicional de los usuarios autenticados
-- Roles: 'admin' (acceso total) y 'staff' (solo lectura)

CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('admin', 'staff')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Comentarios de la tabla
COMMENT ON TABLE profiles IS 'Perfiles de usuario con roles del sistema';
COMMENT ON COLUMN profiles.role IS 'Rol del usuario: admin (acceso total) o staff (solo lectura)';

-- ============================================
-- 2. TABLA DE CLIENTES
-- ============================================
-- Almacena los clientes de SoftControl

CREATE TABLE clients (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT,
  company TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL
);

-- Índices para mejorar búsquedas
CREATE INDEX idx_clients_email ON clients(email);
CREATE INDEX idx_clients_company ON clients(company);
CREATE INDEX idx_clients_created_by ON clients(created_by);

-- Comentarios
COMMENT ON TABLE clients IS 'Clientes de SoftControl';
COMMENT ON COLUMN clients.created_by IS 'Usuario que creó el cliente';

-- ============================================
-- 3. TABLA DE PRODUCTOS
-- ============================================
-- Catálogo de productos que ofrece SoftControl
-- Cada producto tiene dos tipos de precio: pago único y suscripción

CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  price_one_payment NUMERIC(10, 2) NOT NULL DEFAULT 0,
  price_subscription NUMERIC(10, 2) NOT NULL DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índice para búsquedas por nombre
CREATE INDEX idx_products_name ON products(name);

-- Comentarios
COMMENT ON TABLE products IS 'Productos ofrecidos por SoftControl';
COMMENT ON COLUMN products.price_one_payment IS 'Precio para licencia de pago único';
COMMENT ON COLUMN products.price_subscription IS 'Precio mensual para suscripción';

-- ============================================
-- 4. TABLA DE LICENCIAS
-- ============================================
-- Licencias asignadas a clientes
-- Tipos: 'licencia_unica' (pago único) o 'suscripcion' (pago recurrente)
-- Estados: 'activa', 'inactiva', 'pendiente_pago'

CREATE TABLE licenses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('licencia_unica', 'suscripcion')),
  start_date DATE NOT NULL,
  end_date DATE,
  status TEXT NOT NULL DEFAULT 'activa' CHECK (status IN ('activa', 'inactiva', 'pendiente_pago')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para mejorar consultas
CREATE INDEX idx_licenses_client_id ON licenses(client_id);
CREATE INDEX idx_licenses_product_id ON licenses(product_id);
CREATE INDEX idx_licenses_status ON licenses(status);
CREATE INDEX idx_licenses_type ON licenses(type);
CREATE INDEX idx_licenses_end_date ON licenses(end_date);

-- Comentarios
COMMENT ON TABLE licenses IS 'Licencias asignadas a clientes';
COMMENT ON COLUMN licenses.type IS 'Tipo de licencia: licencia_unica o suscripcion';
COMMENT ON COLUMN licenses.status IS 'Estado: activa, inactiva o pendiente_pago';
COMMENT ON COLUMN licenses.end_date IS 'Fecha de vencimiento (NULL para licencias únicas perpetuas)';

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================
-- Configuración de seguridad a nivel de fila
-- Administradores: acceso total (SELECT, INSERT, UPDATE, DELETE)
-- Staff: solo lectura (SELECT)
-- Solo usuarios autenticados pueden acceder

-- Habilitar RLS en todas las tablas
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE licenses ENABLE ROW LEVEL SECURITY;

-- ============================================
-- POLÍTICAS RLS - PROFILES
-- ============================================

-- Los usuarios pueden ver su propio perfil
CREATE POLICY "Users can view their own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

-- Los usuarios pueden actualizar su propio perfil
CREATE POLICY "Users can update their own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

-- ============================================
-- POLÍTICAS RLS - CLIENTS
-- ============================================

-- Función auxiliar para verificar si el usuario es admin
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Todos los usuarios autenticados pueden ver clientes
CREATE POLICY "Authenticated users can view clients"
  ON clients FOR SELECT
  TO authenticated
  USING (true);

-- Solo administradores pueden insertar clientes
CREATE POLICY "Only admins can insert clients"
  ON clients FOR INSERT
  TO authenticated
  WITH CHECK (is_admin());

-- Solo administradores pueden actualizar clientes
CREATE POLICY "Only admins can update clients"
  ON clients FOR UPDATE
  TO authenticated
  USING (is_admin());

-- Solo administradores pueden eliminar clientes
CREATE POLICY "Only admins can delete clients"
  ON clients FOR DELETE
  TO authenticated
  USING (is_admin());

-- ============================================
-- POLÍTICAS RLS - PRODUCTS
-- ============================================

-- Todos los usuarios autenticados pueden ver productos
CREATE POLICY "Authenticated users can view products"
  ON products FOR SELECT
  TO authenticated
  USING (true);

-- Solo administradores pueden insertar productos
CREATE POLICY "Only admins can insert products"
  ON products FOR INSERT
  TO authenticated
  WITH CHECK (is_admin());

-- Solo administradores pueden actualizar productos
CREATE POLICY "Only admins can update products"
  ON products FOR UPDATE
  TO authenticated
  USING (is_admin());

-- Solo administradores pueden eliminar productos
CREATE POLICY "Only admins can delete products"
  ON products FOR DELETE
  TO authenticated
  USING (is_admin());

-- ============================================
-- POLÍTICAS RLS - LICENSES
-- ============================================

-- Todos los usuarios autenticados pueden ver licencias
CREATE POLICY "Authenticated users can view licenses"
  ON licenses FOR SELECT
  TO authenticated
  USING (true);

-- Solo administradores pueden insertar licencias
CREATE POLICY "Only admins can insert licenses"
  ON licenses FOR INSERT
  TO authenticated
  WITH CHECK (is_admin());

-- Solo administradores pueden actualizar licencias
CREATE POLICY "Only admins can update licenses"
  ON licenses FOR UPDATE
  TO authenticated
  USING (is_admin());

-- Solo administradores pueden eliminar licencias
CREATE POLICY "Only admins can delete licenses"
  ON licenses FOR DELETE
  TO authenticated
  USING (is_admin());

-- ============================================
-- TRIGGERS
-- ============================================

-- Función para crear perfil automáticamente al registrar usuario
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'Usuario'),
    COALESCE(NEW.raw_user_meta_data->>'role', 'staff')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger que se ejecuta al crear un nuevo usuario
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- DATOS INICIALES (SEED DATA)
-- ============================================

-- Insertar productos de ejemplo
INSERT INTO products (name, description, price_one_payment, price_subscription) VALUES
  ('Microsoft Office Professional', 'Suite completa de productividad con Word, Excel, PowerPoint y más', 299.99, 12.99),
  ('Adobe Creative Cloud', 'Acceso a todas las aplicaciones de Adobe (Photoshop, Illustrator, Premiere, etc.)', 599.99, 54.99),
  ('AutoCAD', 'Software de diseño asistido por computadora para arquitectura e ingeniería', 1899.99, 185.00),
  ('Antivirus Enterprise', 'Protección avanzada para empresas con gestión centralizada', 149.99, 9.99),
  ('CRM Business Suite', 'Sistema completo de gestión de relaciones con clientes', 499.99, 39.99);

-- ============================================
-- VISTAS ÚTILES
-- ============================================

-- Vista para obtener licencias con información completa
CREATE OR REPLACE VIEW licenses_full AS
SELECT 
  l.id,
  l.type,
  l.start_date,
  l.end_date,
  l.status,
  l.created_at,
  -- Información del cliente
  c.id as client_id,
  c.name as client_name,
  c.email as client_email,
  c.company as client_company,
  -- Información del producto
  p.id as product_id,
  p.name as product_name,
  p.description as product_description,
  CASE 
    WHEN l.type = 'licencia_unica' THEN p.price_one_payment
    WHEN l.type = 'suscripcion' THEN p.price_subscription
  END as price,
  -- Información adicional
  CASE 
    WHEN l.end_date IS NULL THEN false
    WHEN l.end_date < CURRENT_DATE THEN true
    ELSE false
  END as is_expired
FROM licenses l
JOIN clients c ON l.client_id = c.id
JOIN products p ON l.product_id = p.id;

-- Comentario de la vista
COMMENT ON VIEW licenses_full IS 'Vista completa de licencias con información de clientes y productos';

-- ============================================
-- FUNCIONES ÚTILES
-- ============================================

-- Función para obtener estadísticas del dashboard
CREATE OR REPLACE FUNCTION get_dashboard_stats()
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_build_object(
    'total_clients', (SELECT COUNT(*) FROM clients),
    'total_products', (SELECT COUNT(*) FROM products),
    'total_licenses', (SELECT COUNT(*) FROM licenses),
    'active_licenses', (SELECT COUNT(*) FROM licenses WHERE status = 'activa'),
    'inactive_licenses', (SELECT COUNT(*) FROM licenses WHERE status = 'inactiva'),
    'pending_payment_licenses', (SELECT COUNT(*) FROM licenses WHERE status = 'pendiente_pago'),
    'expired_licenses', (SELECT COUNT(*) FROM licenses WHERE end_date < CURRENT_DATE AND end_date IS NOT NULL)
  ) INTO result;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- INSTRUCCIONES DE USO
-- ============================================

-- Para crear un usuario administrador manualmente:
-- 1. Registra el usuario en Supabase Auth
-- 2. Actualiza su rol en la tabla profiles:
--    UPDATE profiles SET role = 'admin' WHERE id = 'user-uuid-aqui';

-- Para crear un cliente de ejemplo:
-- INSERT INTO clients (name, email, phone, company, created_by)
-- VALUES ('Juan Pérez', 'juan@ejemplo.com', '+34 600 123 456', 'Empresa XYZ', 'admin-user-id');

-- Para crear una licencia:
-- INSERT INTO licenses (client_id, product_id, type, start_date, end_date, status)
-- VALUES ('client-uuid', 'product-uuid', 'suscripcion', '2024-01-01', '2024-12-31', 'activa');

-- ============================================
-- FIN DEL ESQUEMA
-- ============================================
