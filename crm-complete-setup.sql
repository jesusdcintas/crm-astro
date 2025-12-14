-- ============================================
-- CRM COMPLETE DATABASE SETUP WITH TEST DATA
-- SoftControl CRM - Sistema de Gestión Empresarial
-- ============================================

-- Habilitar extensiones necesarias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- TABLA: PERFILES DE USUARIO
-- ============================================
-- Almacena información adicional de los usuarios autenticados
-- Roles: 'admin' (acceso total) y 'staff' (solo lectura)

CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('admin', 'staff')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE profiles IS 'Perfiles de usuario con roles del sistema';
COMMENT ON COLUMN profiles.role IS 'Rol del usuario: admin (acceso total) o staff (solo lectura)';

-- ============================================
-- TABLA: CLIENTES
-- ============================================
CREATE TABLE IF NOT EXISTS clients (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT,
  company TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL
);

-- ============================================
-- TABLA: PRODUCTOS
-- ============================================
CREATE TABLE IF NOT EXISTS products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  price_one_payment NUMERIC(10, 2) NOT NULL DEFAULT 0,
  price_subscription NUMERIC(10, 2) NOT NULL DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- TABLA: LICENCIAS
-- ============================================
CREATE TABLE IF NOT EXISTS licenses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('licencia_unica', 'suscripcion')),
  start_date DATE NOT NULL,
  end_date DATE,
  status TEXT NOT NULL DEFAULT 'activa' CHECK (status IN ('activa', 'inactiva', 'pendiente_pago')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- TABLA: PAGOS
-- ============================================
CREATE TABLE IF NOT EXISTS payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  license_id UUID REFERENCES licenses(id) ON DELETE SET NULL,
  amount NUMERIC NOT NULL,
  currency TEXT NOT NULL DEFAULT 'EUR',
  payment_method TEXT,
  paid_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- TABLA: PAGOS
-- ============================================
CREATE TABLE IF NOT EXISTS payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  license_id UUID REFERENCES licenses(id) ON DELETE SET NULL,
  amount NUMERIC NOT NULL,
  currency TEXT NOT NULL DEFAULT 'EUR',
  payment_method TEXT,
  paid_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- TABLA: CUPONES
-- ============================================
CREATE TABLE IF NOT EXISTS coupons (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code TEXT NOT NULL UNIQUE,
  description TEXT,
  discount_type TEXT NOT NULL CHECK (discount_type IN ('percentage', 'fixed_amount')),
  discount_value NUMERIC NOT NULL,
  max_uses INTEGER,
  current_uses INTEGER DEFAULT 0,
  max_uses_per_client INTEGER DEFAULT 1,
  min_purchase_amount NUMERIC,
  valid_from TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  valid_until TIMESTAMP WITH TIME ZONE,
  is_active BOOLEAN DEFAULT true,
  applicable_products UUID[],
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL
);

-- ============================================
-- TABLA: USO DE CUPONES
-- ============================================
CREATE TABLE IF NOT EXISTS coupon_usage (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  coupon_id UUID NOT NULL REFERENCES coupons(id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  payment_id UUID REFERENCES payments(id) ON DELETE SET NULL,
  discount_applied NUMERIC NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- TABLA: NOTIFICACIONES DE LICENCIAS
-- ============================================
CREATE TABLE IF NOT EXISTS license_notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  license_id UUID NOT NULL REFERENCES licenses(id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  notification_type TEXT NOT NULL CHECK (notification_type IN ('expiration_warning', 'expired', 'renewed')),
  days_before_expiration INTEGER,
  sent BOOLEAN DEFAULT false,
  sent_at TIMESTAMP WITH TIME ZONE,
  email_sent_to TEXT,
  error_message TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- TABLA: REGISTRO DE ACTIVIDADES
-- ============================================
CREATE TABLE IF NOT EXISTS activity_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id UUID,
  description TEXT,
  metadata JSONB,
  ip_address INET,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- TABLA: CONFIGURACIÓN DEL SISTEMA
-- ============================================
CREATE TABLE IF NOT EXISTS system_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  key TEXT NOT NULL UNIQUE,
  value JSONB NOT NULL,
  description TEXT,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_by UUID REFERENCES profiles(id) ON DELETE SET NULL
);

-- ============================================
-- TABLA: CONTACTOS (Personas de contacto de clientes)
-- ============================================
CREATE TABLE IF NOT EXISTS contacts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100),
  email VARCHAR(255),
  phone VARCHAR(50),
  position VARCHAR(100),
  is_primary BOOLEAN DEFAULT false,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- TABLA: INTERACCIONES (Historial de comunicaciones)
-- ============================================
CREATE TABLE IF NOT EXISTS interactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  contact_id UUID REFERENCES contacts(id) ON DELETE SET NULL,
  interaction_type VARCHAR(50) NOT NULL, -- 'call', 'email', 'meeting', 'note', 'task'
  subject VARCHAR(255),
  description TEXT,
  interaction_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID, -- Referencia al usuario que creó la interacción
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- TABLA: TAREAS
-- ============================================
CREATE TABLE IF NOT EXISTS tasks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'in_progress', 'completed', 'cancelled'
  priority VARCHAR(20) DEFAULT 'medium', -- 'low', 'medium', 'high', 'urgent'
  due_date TIMESTAMP WITH TIME ZONE,
  assigned_to UUID, -- Referencia al usuario asignado
  created_by UUID, -- Referencia al usuario que creó la tarea
  completed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- TABLA: ETIQUETAS
-- ============================================
CREATE TABLE IF NOT EXISTS tags (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(50) NOT NULL UNIQUE,
  color VARCHAR(7) DEFAULT '#6366f1',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- TABLA: RELACIÓN CLIENTES-ETIQUETAS
-- ============================================
CREATE TABLE IF NOT EXISTS client_tags (
  client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  tag_id UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  PRIMARY KEY (client_id, tag_id)
);

-- ============================================
-- TABLA: NOTIFICACIONES DE SUSCRIPCIONES
-- ============================================
CREATE TABLE IF NOT EXISTS subscription_notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  license_id UUID NOT NULL REFERENCES licenses(id) ON DELETE CASCADE,
  notification_type VARCHAR(50) NOT NULL, -- 'expiring_soon', 'expired', 'payment_due'
  notification_date DATE NOT NULL,
  sent_at TIMESTAMP WITH TIME ZONE,
  email_sent BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- ÍNDICES PARA MEJORAR RENDIMIENTO
-- ============================================
CREATE INDEX IF NOT EXISTS idx_clients_email ON clients(email);
CREATE INDEX IF NOT EXISTS idx_clients_company ON clients(company);
CREATE INDEX IF NOT EXISTS idx_clients_created_at ON clients(created_at);
CREATE INDEX IF NOT EXISTS idx_clients_created_by ON clients(created_by);

CREATE INDEX IF NOT EXISTS idx_licenses_client_id ON licenses(client_id);
CREATE INDEX IF NOT EXISTS idx_licenses_product_id ON licenses(product_id);
CREATE INDEX IF NOT EXISTS idx_licenses_status ON licenses(status);
CREATE INDEX IF NOT EXISTS idx_licenses_type ON licenses(type);
CREATE INDEX IF NOT EXISTS idx_licenses_end_date ON licenses(end_date);

CREATE INDEX IF NOT EXISTS idx_payments_client_id ON payments(client_id);
CREATE INDEX IF NOT EXISTS idx_payments_license_id ON payments(license_id);
CREATE INDEX IF NOT EXISTS idx_payments_paid_at ON payments(paid_at);
CREATE INDEX IF NOT EXISTS idx_payments_created_at ON payments(created_at);

CREATE INDEX IF NOT EXISTS idx_coupons_code ON coupons(code);
CREATE INDEX IF NOT EXISTS idx_coupons_is_active ON coupons(is_active);
CREATE INDEX IF NOT EXISTS idx_coupon_usage_coupon_id ON coupon_usage(coupon_id);
CREATE INDEX IF NOT EXISTS idx_coupon_usage_client_id ON coupon_usage(client_id);

CREATE INDEX IF NOT EXISTS idx_license_notifications_license_id ON license_notifications(license_id);
CREATE INDEX IF NOT EXISTS idx_license_notifications_sent ON license_notifications(sent);

CREATE INDEX IF NOT EXISTS idx_activity_log_user_id ON activity_log(user_id);
CREATE INDEX IF NOT EXISTS idx_activity_log_entity_type ON activity_log(entity_type);
CREATE INDEX IF NOT EXISTS idx_activity_log_created_at ON activity_log(created_at);

CREATE INDEX IF NOT EXISTS idx_contacts_client_id ON contacts(client_id);
CREATE INDEX IF NOT EXISTS idx_interactions_client_id ON interactions(client_id);
CREATE INDEX IF NOT EXISTS idx_tasks_client_id ON tasks(client_id);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);

-- ============================================
-- FUNCIONES Y TRIGGERS
-- ============================================

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers para actualizar updated_at
CREATE TRIGGER update_coupons_updated_at BEFORE UPDATE ON coupons
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_system_settings_updated_at BEFORE UPDATE ON system_settings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

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
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

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

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

-- Habilitar RLS en todas las tablas
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE licenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE coupons ENABLE ROW LEVEL SECURITY;
ALTER TABLE coupon_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE license_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE client_tags ENABLE ROW LEVEL SECURITY;

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
-- POLÍTICAS RLS - PAYMENTS
-- ============================================

-- Todos los usuarios autenticados pueden ver pagos
CREATE POLICY "Authenticated users can view payments"
  ON payments FOR SELECT
  TO authenticated
  USING (true);

-- Solo administradores pueden gestionar pagos
CREATE POLICY "Only admins can manage payments"
  ON payments FOR ALL
  TO authenticated
  USING (is_admin());

-- ============================================
-- POLÍTICAS RLS - OTRAS TABLAS
-- ============================================

-- Coupons: todos pueden ver, solo admins editar
CREATE POLICY "Authenticated users can view coupons"
  ON coupons FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Only admins can insert coupons"
  ON coupons FOR INSERT
  TO authenticated
  WITH CHECK (is_admin());

CREATE POLICY "Only admins can update coupons"
  ON coupons FOR UPDATE
  TO authenticated
  USING (is_admin());

CREATE POLICY "Only admins can delete coupons"
  ON coupons FOR DELETE
  TO authenticated
  USING (is_admin());

-- Coupon usage: solo lectura para todos, escritura para admins
CREATE POLICY "Authenticated users can view coupon usage"
  ON coupon_usage FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Only admins can insert coupon usage"
  ON coupon_usage FOR INSERT
  TO authenticated
  WITH CHECK (is_admin());

CREATE POLICY "Only admins can update coupon usage"
  ON coupon_usage FOR UPDATE
  TO authenticated
  USING (is_admin());

CREATE POLICY "Only admins can delete coupon usage"
  ON coupon_usage FOR DELETE
  TO authenticated
  USING (is_admin());

-- License notifications: todos pueden ver, solo admins editar
CREATE POLICY "Authenticated users can view license notifications"
  ON license_notifications FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Only admins can insert license notifications"
  ON license_notifications FOR INSERT
  TO authenticated
  WITH CHECK (is_admin());

CREATE POLICY "Only admins can update license notifications"
  ON license_notifications FOR UPDATE
  TO authenticated
  USING (is_admin());

CREATE POLICY "Only admins can delete license notifications"
  ON license_notifications FOR DELETE
  TO authenticated
  USING (is_admin());

-- Activity log: todos pueden ver, solo admins editar
CREATE POLICY "Authenticated users can view activity log"
  ON activity_log FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Only admins can insert activity log"
  ON activity_log FOR INSERT
  TO authenticated
  WITH CHECK (is_admin());

CREATE POLICY "Only admins can update activity log"
  ON activity_log FOR UPDATE
  TO authenticated
  USING (is_admin());

CREATE POLICY "Only admins can delete activity log"
  ON activity_log FOR DELETE
  TO authenticated
  USING (is_admin());

-- System settings: todos pueden ver, solo admins editar
CREATE POLICY "Authenticated users can view system settings"
  ON system_settings FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Only admins can insert system settings"
  ON system_settings FOR INSERT
  TO authenticated
  WITH CHECK (is_admin());

CREATE POLICY "Only admins can update system settings"
  ON system_settings FOR UPDATE
  TO authenticated
  USING (is_admin());

CREATE POLICY "Only admins can delete system settings"
  ON system_settings FOR DELETE
  TO authenticated
  USING (is_admin());

-- ============================================
-- POLÍTICAS RLS - CONTACTS
-- ============================================

CREATE POLICY "Authenticated users can view contacts"
  ON contacts FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Only admins can insert contacts"
  ON contacts FOR INSERT
  TO authenticated
  WITH CHECK (is_admin());

CREATE POLICY "Only admins can update contacts"
  ON contacts FOR UPDATE
  TO authenticated
  USING (is_admin());

CREATE POLICY "Only admins can delete contacts"
  ON contacts FOR DELETE
  TO authenticated
  USING (is_admin());

-- ============================================
-- POLÍTICAS RLS - INTERACTIONS
-- ============================================

CREATE POLICY "Authenticated users can view interactions"
  ON interactions FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Only admins can insert interactions"
  ON interactions FOR INSERT
  TO authenticated
  WITH CHECK (is_admin());

CREATE POLICY "Only admins can update interactions"
  ON interactions FOR UPDATE
  TO authenticated
  USING (is_admin());

CREATE POLICY "Only admins can delete interactions"
  ON interactions FOR DELETE
  TO authenticated
  USING (is_admin());

-- ============================================
-- POLÍTICAS RLS - TASKS
-- ============================================

CREATE POLICY "Authenticated users can view tasks"
  ON tasks FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Only admins can insert tasks"
  ON tasks FOR INSERT
  TO authenticated
  WITH CHECK (is_admin());

CREATE POLICY "Only admins can update tasks"
  ON tasks FOR UPDATE
  TO authenticated
  USING (is_admin());

CREATE POLICY "Only admins can delete tasks"
  ON tasks FOR DELETE
  TO authenticated
  USING (is_admin());

-- ============================================
-- POLÍTICAS RLS - TAGS
-- ============================================

CREATE POLICY "Authenticated users can view tags"
  ON tags FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Only admins can insert tags"
  ON tags FOR INSERT
  TO authenticated
  WITH CHECK (is_admin());

CREATE POLICY "Only admins can update tags"
  ON tags FOR UPDATE
  TO authenticated
  USING (is_admin());

CREATE POLICY "Only admins can delete tags"
  ON tags FOR DELETE
  TO authenticated
  USING (is_admin());

-- ============================================
-- POLÍTICAS RLS - CLIENT_TAGS
-- ============================================

CREATE POLICY "Authenticated users can view client tags"
  ON client_tags FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Only admins can insert client tags"
  ON client_tags FOR INSERT
  TO authenticated
  WITH CHECK (is_admin());

CREATE POLICY "Only admins can update client tags"
  ON client_tags FOR UPDATE
  TO authenticated
  USING (is_admin());

CREATE POLICY "Only admins can delete client tags"
  ON client_tags FOR DELETE
  TO authenticated
  USING (is_admin());

-- ============================================
-- DATOS DE PRUEBA
-- ============================================

-- CLIENTES
INSERT INTO clients (name, email, phone, company, address, city, postal_code, country, notes) VALUES
('Juan Pérez', 'juan.perez@empresa1.com', '+34 600 111 222', 'Empresa Innovadora SL', 'Calle Mayor 123', 'Madrid', '28001', 'España', 'Cliente VIP desde 2023'),
('María García', 'maria.garcia@techcorp.es', '+34 600 333 444', 'TechCorp Solutions', 'Av. Diagonal 456', 'Barcelona', '08008', 'España', 'Interesada en soluciones enterprise'),
('Carlos Rodríguez', 'carlos.r@startup.io', '+34 600 555 666', 'Startup Digital SL', 'Calle Serrano 789', 'Madrid', '28006', 'España', 'Startup en fase de crecimiento'),
('Ana Martínez', 'ana.martinez@pyme.com', '+34 600 777 888', 'PYME Gestión', 'Ronda Sant Pere 12', 'Barcelona', '08010', 'España', NULL),
('David López', 'david.lopez@comercial.es', '+34 600 999 000', 'Comercial Mediterráneo', 'Avenida del Puerto 45', 'Valencia', '46023', 'España', 'Cliente desde 2022'),
('Laura Sánchez', 'laura.s@consulting.com', '+34 611 222 333', 'Business Consulting Group', 'Paseo de Gracia 88', 'Barcelona', '08008', 'España', 'Consultora especializada'),
('Roberto Fernández', 'roberto@inmobiliaria.es', '+34 622 444 555', 'Inmobiliaria del Sur', 'Calle Larios 15', 'Málaga', '29015', 'España', NULL),
('Elena Torres', 'elena.torres@educacion.org', '+34 633 666 777', 'Centro Educativo Digital', 'Gran Vía 200', 'Madrid', '28013', 'España', 'Sector educación'),
('Miguel Ramírez', 'miguel.r@logistica.net', '+34 644 888 999', 'LogiTrans Europa', 'Polígono Industrial Norte', 'Zaragoza', '50197', 'España', 'Empresa de logística'),
('Carmen Díaz', 'carmen.diaz@salud.es', '+34 655 111 222', 'Clínica Salud Integral', 'Avenida Constitución 50', 'Sevilla', '41001', 'España', 'Sector salud');

-- ============================================
-- DATOS DE PRUEBA
-- ============================================

-- PRODUCTOS
INSERT INTO products (name, description, price_one_payment, price_subscription) VALUES
('CRM Básico', 'Sistema CRM completo para pequeñas empresas con gestión de contactos, ventas y tareas', 499.00, 29.00),
('CRM Profesional', 'CRM avanzado con automatización de marketing y análisis profundo', 999.00, 79.00),
('CRM Enterprise', 'Solución enterprise con funcionalidades ilimitadas y soporte dedicado', 2499.00, 199.00),
('Módulo Facturación', 'Sistema de facturación integrado con el CRM', 299.00, 19.00),
('Módulo Inventario', 'Control de stock y gestión de almacén', 399.00, 25.00),
('Suite Completa', 'Todos los módulos incluidos en un solo paquete', 3999.00, 249.00)
ON CONFLICT DO NOTHING;

-- LICENCIAS
INSERT INTO licenses (client_id, product_id, type, start_date, end_date, status) VALUES
((SELECT id FROM clients WHERE email = 'juan.perez@empresa1.com'), 
 (SELECT id FROM products WHERE name = 'CRM Profesional'), 
 'suscripcion', '2024-01-15', '2025-01-15', 'activa'),

((SELECT id FROM clients WHERE email = 'maria.garcia@techcorp.es'), 
 (SELECT id FROM products WHERE name = 'CRM Enterprise'), 
 'suscripcion', '2024-02-01', '2025-02-01', 'activa'),

((SELECT id FROM clients WHERE email = 'carlos.r@startup.io'), 
 (SELECT id FROM products WHERE name = 'CRM Básico'), 
 'suscripcion', '2024-03-10', '2025-03-10', 'activa'),

((SELECT id FROM clients WHERE email = 'ana.martinez@pyme.com'), 
 (SELECT id FROM products WHERE name = 'CRM Básico'), 
 'licencia_unica', '2024-01-20', NULL, 'activa'),

((SELECT id FROM clients WHERE email = 'david.lopez@comercial.es'), 
 (SELECT id FROM products WHERE name = 'Módulo Facturación'), 
 'suscripcion', '2024-04-01', '2025-04-01', 'activa'),

((SELECT id FROM clients WHERE email = 'laura.s@consulting.com'), 
 (SELECT id FROM products WHERE name = 'Suite Completa'), 
 'suscripcion', '2024-05-15', '2025-05-15', 'activa'),

((SELECT id FROM clients WHERE email = 'roberto@inmobiliaria.es'), 
 (SELECT id FROM products WHERE name = 'CRM Profesional'), 
 'suscripcion', '2024-06-01', '2025-01-01', 'activa'),

((SELECT id FROM clients WHERE email = 'elena.torres@educacion.org'), 
 (SELECT id FROM products WHERE name = 'CRM Básico'), 
 'suscripcion', '2023-09-01', '2024-09-01', 'inactiva'),

((SELECT id FROM clients WHERE email = 'miguel.r@logistica.net'), 
 (SELECT id FROM products WHERE name = 'Módulo Inventario'), 
 'suscripcion', '2024-07-01', '2025-07-01', 'activa'),

((SELECT id FROM clients WHERE email = 'carmen.diaz@salud.es'), 
 (SELECT id FROM products WHERE name = 'CRM Profesional'), 
 'suscripcion', '2024-12-01', '2025-12-01', 'pendiente_pago')
ON CONFLICT DO NOTHING;

-- PAGOS (Historial simplificado de 2025 - últimos 6 meses)
-- Usaremos una estrategia diferente: insertar pagos sin referencia a license_key
DO $$
DECLARE
  client_juan UUID;
  client_maria UUID;
  client_carlos UUID;
  client_david UUID;
  client_laura UUID;
  client_miguel UUID;
BEGIN
  -- Obtener IDs de clientes
  SELECT id INTO client_juan FROM clients WHERE email = 'juan.perez@empresa1.com';
  SELECT id INTO client_maria FROM clients WHERE email = 'maria.garcia@techcorp.es';
  SELECT id INTO client_carlos FROM clients WHERE email = 'carlos.r@startup.io';
  SELECT id INTO client_david FROM clients WHERE email = 'david.lopez@comercial.es';
  SELECT id INTO client_laura FROM clients WHERE email = 'laura.s@consulting.com';
  SELECT id INTO client_miguel FROM clients WHERE email = 'miguel.r@logistica.net';
  
  -- Julio 2025
  INSERT INTO payments (client_id, amount, currency, payment_method, paid_at, created_at) VALUES
  (client_juan, 79.00, 'EUR', 'card', '2025-07-15 10:30:00', '2025-07-15 10:30:00'),
  (client_maria, 199.00, 'EUR', 'transfer', '2025-07-20 14:15:00', '2025-07-20 14:15:00'),
  (client_carlos, 29.00, 'EUR', 'paypal', '2025-07-10 09:00:00', '2025-07-10 09:00:00');
  
  -- Agosto 2025
  INSERT INTO payments (client_id, amount, currency, payment_method, paid_at, created_at) VALUES
  (client_juan, 79.00, 'EUR', 'card', '2025-08-15 10:30:00', '2025-08-15 10:30:00'),
  (client_maria, 199.00, 'EUR', 'transfer', '2025-08-20 14:15:00', '2025-08-20 14:15:00'),
  (client_david, 19.00, 'EUR', 'card', '2025-08-01 11:00:00', '2025-08-01 11:00:00');
  
  -- Septiembre 2025
  INSERT INTO payments (client_id, amount, currency, payment_method, paid_at, created_at) VALUES
  (client_juan, 79.00, 'EUR', 'card', '2025-09-15 10:30:00', '2025-09-15 10:30:00'),
  (client_carlos, 29.00, 'EUR', 'paypal', '2025-09-10 09:00:00', '2025-09-10 09:00:00'),
  (client_miguel, 25.00, 'EUR', 'paypal', '2025-09-01 13:30:00', '2025-09-01 13:30:00');
  
  -- Octubre 2025
  INSERT INTO payments (client_id, amount, currency, payment_method, paid_at, created_at) VALUES
  (client_juan, 79.00, 'EUR', 'card', '2025-10-15 10:30:00', '2025-10-15 10:30:00'),
  (client_david, 19.00, 'EUR', 'card', '2025-10-01 11:00:00', '2025-10-01 11:00:00'),
  (client_laura, 249.00, 'EUR', 'transfer', '2025-10-15 16:00:00', '2025-10-15 16:00:00');
  
  -- Noviembre 2025
  INSERT INTO payments (client_id, amount, currency, payment_method, paid_at, created_at) VALUES
  (client_juan, 79.00, 'EUR', 'card', '2025-11-15 10:30:00', '2025-11-15 10:30:00'),
  (client_maria, 199.00, 'EUR', 'transfer', '2025-11-20 14:15:00', '2025-11-20 14:15:00'),
  (client_miguel, 25.00, 'EUR', 'paypal', '2025-11-01 13:30:00', '2025-11-01 13:30:00');
  
  -- Diciembre 2025
  INSERT INTO payments (client_id, amount, currency, payment_method, paid_at, created_at) VALUES
  (client_juan, 79.00, 'EUR', 'card', '2025-12-15 10:30:00', '2025-12-15 10:30:00'),
  (client_carlos, 29.00, 'EUR', 'paypal', '2025-12-10 09:00:00', '2025-12-10 09:00:00'),
  (client_laura, 249.00, 'EUR', 'transfer', '2025-12-15 16:00:00', '2025-12-15 16:00:00');
  
END $$;

-- CONTACTOS (Personas de contacto)
INSERT INTO contacts (client_id, first_name, last_name, email, phone, position, is_primary) VALUES
((SELECT id FROM clients WHERE email = 'juan.perez@empresa1.com'), 
 'Juan', 'Pérez', 'juan.perez@empresa1.com', '+34 600 111 222', 'CEO', true),

((SELECT id FROM clients WHERE email = 'maria.garcia@techcorp.es'), 
 'María', 'García', 'maria.garcia@techcorp.es', '+34 600 333 444', 'CTO', true),

((SELECT id FROM clients WHERE email = 'maria.garcia@techcorp.es'), 
 'Pedro', 'Sánchez', 'pedro.sanchez@techcorp.es', '+34 600 333 445', 'Director de IT', false),

((SELECT id FROM clients WHERE email = 'carlos.r@startup.io'), 
 'Carlos', 'Rodríguez', 'carlos.r@startup.io', '+34 600 555 666', 'Fundador', true),

((SELECT id FROM clients WHERE email = 'david.lopez@comercial.es'), 
 'David', 'López', 'david.lopez@comercial.es', '+34 600 999 000', 'Director Comercial', true);

-- ETIQUETAS
INSERT INTO tags (name, color) VALUES
('VIP', '#f43f5e'),
('Nuevo', '#10b981'),
('Prioritario', '#f59e0b'),
('Recurrente', '#6366f1'),
('En riesgo', '#ef4444'),
('Potencial', '#8b5cf6')
ON CONFLICT DO NOTHING;

-- RELACIÓN CLIENTES-ETIQUETAS
INSERT INTO client_tags (client_id, tag_id) VALUES
((SELECT id FROM clients WHERE email = 'juan.perez@empresa1.com'), 
 (SELECT id FROM tags WHERE name = 'VIP')),
((SELECT id FROM clients WHERE email = 'juan.perez@empresa1.com'), 
 (SELECT id FROM tags WHERE name = 'Recurrente')),
((SELECT id FROM clients WHERE email = 'maria.garcia@techcorp.es'), 
 (SELECT id FROM tags WHERE name = 'VIP')),
((SELECT id FROM clients WHERE email = 'carlos.r@startup.io'), 
 (SELECT id FROM tags WHERE name = 'Nuevo')),
((SELECT id FROM clients WHERE email = 'elena.torres@educacion.org'), 
 (SELECT id FROM tags WHERE name = 'En riesgo'));

-- INTERACCIONES
INSERT INTO interactions (client_id, contact_id, interaction_type, subject, description, interaction_date) VALUES
((SELECT id FROM clients WHERE email = 'juan.perez@empresa1.com'),
 (SELECT id FROM contacts WHERE email = 'juan.perez@empresa1.com'),
 'call', 'Seguimiento mensual', 'Llamada de seguimiento. Cliente satisfecho con el servicio.', '2025-12-01 10:00:00'),

((SELECT id FROM clients WHERE email = 'maria.garcia@techcorp.es'),
 (SELECT id FROM contacts WHERE email = 'maria.garcia@techcorp.es'),
 'email', 'Propuesta de upgrade', 'Enviada propuesta para actualizar a plan Enterprise.', '2025-12-05 14:30:00'),

((SELECT id FROM clients WHERE email = 'carlos.r@startup.io'),
 (SELECT id FROM contacts WHERE email = 'carlos.r@startup.io'),
 'meeting', 'Reunión de onboarding', 'Primera reunión para configurar el CRM.', '2025-03-15 11:00:00')
ON CONFLICT DO NOTHING;

-- TAREAS
INSERT INTO tasks (client_id, title, description, status, priority, due_date) VALUES
((SELECT id FROM clients WHERE email = 'juan.perez@empresa1.com'),
 'Renovación de licencia', 'Contactar para renovación antes del vencimiento', 'pending', 'high', '2025-01-10 00:00:00'),

((SELECT id FROM clients WHERE email = 'maria.garcia@techcorp.es'),
 'Enviar documentación técnica', 'Preparar y enviar documentación de API', 'in_progress', 'medium', '2025-12-20 00:00:00'),

((SELECT id FROM clients WHERE email = 'elena.torres@educacion.org'),
 'Seguimiento cliente inactivo', 'Contactar para reactivar licencia expirada', 'pending', 'high', '2025-12-15 00:00:00'),

((SELECT id FROM clients WHERE email = 'carmen.diaz@salud.es'),
 'Resolver pendiente de pago', 'Gestionar pago pendiente de diciembre', 'pending', 'urgent', '2025-12-16 00:00:00')
ON CONFLICT DO NOTHING;

-- ============================================
-- VISTAS ÚTILES
-- ============================================

-- Vista de resumen de clientes con estadísticas
CREATE OR REPLACE VIEW client_summary AS
SELECT 
  c.id,
  c.name,
  c.email,
  c.company,
  COUNT(DISTINCT l.id) as total_licenses,
  COUNT(DISTINCT CASE WHEN l.status = 'activa' THEN l.id END) as active_licenses,
  MAX(p.paid_at) as last_payment_date,
  SUM(p.amount) as total_paid
FROM clients c
LEFT JOIN licenses l ON c.id = l.client_id
LEFT JOIN payments p ON c.id = p.client_id
GROUP BY c.id, c.name, c.email, c.company;

-- Vista de licencias próximas a vencer
CREATE OR REPLACE VIEW expiring_licenses AS
SELECT 
  l.id,
  c.name as client_name,
  c.email as client_email,
  p.name as product_name,
  l.end_date,
  l.status,
  EXTRACT(DAY FROM l.end_date - CURRENT_DATE) as days_until_expiry
FROM licenses l
JOIN clients c ON l.client_id = c.id
JOIN products p ON l.product_id = p.id
WHERE l.type = 'suscripcion' 
  AND l.status = 'activa'
  AND l.end_date IS NOT NULL
  AND l.end_date <= CURRENT_DATE + INTERVAL '30 days'
ORDER BY l.end_date;
LEFT JOIN licenses l ON c.id = l.client_id
LEFT JOIN payments p ON c.id = p.client_id
GROUP BY c.id, c.name, c.email, c.company;

-- Vista de licencias próximas a vencer
CREATE OR REPLACE VIEW expiring_licenses AS
SELECT 
  l.id,
  l.license_key,
  c.name as client_name,
  c.email as client_email,
  p.name as product_name,
  l.end_date,
  l.status,
  l.auto_renew,
  EXTRACT(DAY FROM l.end_date - CURRENT_DATE) as days_until_expiry
FROM licenses l
JOIN clients c ON l.client_id = c.id
JOIN products p ON l.product_id = p.id
WHERE l.license_type = 'subscription' 
  AND l.status = 'activa'
  AND l.end_date IS NOT NULL
  AND l.end_date <= CURRENT_DATE + INTERVAL '30 days'
ORDER BY l.end_date;

-- ============================================
-- INFORMACIÓN FINAL
-- ============================================

-- Mostrar resumen de datos insertados
DO $$
DECLARE
  total_clients INTEGER;
  total_products INTEGER;
  total_licenses INTEGER;
  total_payments INTEGER;
BEGIN
  SELECT COUNT(*) INTO total_clients FROM clients;
  SELECT COUNT(*) INTO total_products FROM products;
  SELECT COUNT(*) INTO total_licenses FROM licenses;
  SELECT COUNT(*) INTO total_payments FROM payments;
  
  RAISE NOTICE '✓ Base de datos creada exitosamente';
  RAISE NOTICE '✓ Clientes insertados: %', total_clients;
  RAISE NOTICE '✓ Productos insertados: %', total_products;
  RAISE NOTICE '✓ Licencias insertadas: %', total_licenses;
  RAISE NOTICE '✓ Pagos insertados: %', total_payments;
  RAISE NOTICE '✓ Sistema listo para usar';
END $$;
