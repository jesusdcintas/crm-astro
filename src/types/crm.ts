// ============================================
// TIPOS TYPESCRIPT - MINI-CRM SOFTCONTROL
// ============================================

// ============================================
// ENUMS Y TIPOS BÁSICOS
// ============================================

/**
 * Roles del sistema
 * - admin: Acceso total (crear, editar, eliminar)
 * - staff: Solo lectura
 */
export type UserRole = 'admin' | 'staff';

/**
 * Tipos de licencia
 * - licencia_unica: Pago único, sin fecha de vencimiento
 * - suscripcion: Pago recurrente mensual, con fecha de vencimiento
 */
export type LicenseType = 'licencia_unica' | 'suscripcion';

/**
 * Estados de licencia
 * - activa: Licencia en uso y al día con pagos
 * - inactiva: Licencia desactivada
 * - pendiente_pago: Licencia con pago pendiente
 */
export type LicenseStatus = 'activa' | 'inactiva' | 'pendiente_pago';

// ============================================
// INTERFACES DE ENTIDADES
// ============================================

/**
 * Perfil de usuario
 * Extiende la información del usuario de Supabase Auth
 */
export interface Profile {
  id: string;
  full_name: string;
  role: UserRole;
  created_at: string;
}

/**
 * Cliente de SoftControl
 */
export interface Client {
  id: string;
  name: string;
  email: string;
  phone: string | null;
  company: string | null;
  created_at: string;
  created_by: string | null;
}

/**
 * Producto ofrecido por SoftControl
 */
export interface Product {
  id: string;
  name: string;
  description: string | null;
  price_one_payment: number;
  price_subscription: number;
  created_at: string;
}

/**
 * Licencia asignada a un cliente
 */
export interface License {
  id: string;
  client_id: string;
  product_id: string;
  type: LicenseType;
  start_date: string;
  end_date: string | null;
  status: LicenseStatus;
  created_at: string;
}

/**
 * Licencia con información completa (joins)
 * Incluye datos del cliente y producto
 */
export interface LicenseFull extends License {
  client_name: string;
  client_email: string;
  client_company: string | null;
  product_name: string;
  product_description: string | null;
  price: number;
  is_expired: boolean;
}

/**
 * Cliente con sus licencias
 */
export interface ClientWithLicenses extends Client {
  licenses: LicenseFull[];
}

// ============================================
// TIPOS PARA FORMULARIOS (DTOs)
// ============================================

/**
 * Datos para crear un cliente
 */
export interface CreateClientDTO {
  name: string;
  email: string;
  phone?: string;
  company?: string;
}

/**
 * Datos para actualizar un cliente
 */
export interface UpdateClientDTO {
  name?: string;
  email?: string;
  phone?: string;
  company?: string;
}

/**
 * Datos para crear un producto
 */
export interface CreateProductDTO {
  name: string;
  description?: string;
  price_one_payment: number;
  price_subscription: number;
}

/**
 * Datos para actualizar un producto
 */
export interface UpdateProductDTO {
  name?: string;
  description?: string;
  price_one_payment?: number;
  price_subscription?: number;
}

/**
 * Datos para crear una licencia
 */
export interface CreateLicenseDTO {
  client_id: string;
  product_id: string;
  type: LicenseType;
  start_date: string;
  end_date?: string;
  status?: LicenseStatus;
}

/**
 * Datos para actualizar una licencia
 */
export interface UpdateLicenseDTO {
  type?: LicenseType;
  start_date?: string;
  end_date?: string;
  status?: LicenseStatus;
}

// ============================================
// TIPOS PARA ESTADÍSTICAS
// ============================================

/**
 * Estadísticas del dashboard
 */
export interface DashboardStats {
  total_clients: number;
  total_products: number;
  total_licenses: number;
  active_licenses: number;
  inactive_licenses: number;
  pending_payment_licenses: number;
  expired_licenses: number;
}

// ============================================
// TIPOS PARA RESPUESTAS DE API
// ============================================

/**
 * Respuesta exitosa de API
 */
export interface ApiSuccess<T = any> {
  success: true;
  data: T;
  message?: string;
}

/**
 * Respuesta de error de API
 */
export interface ApiError {
  success: false;
  error: string;
  details?: any;
}

/**
 * Respuesta de API (éxito o error)
 */
export type ApiResponse<T = any> = ApiSuccess<T> | ApiError;

// ============================================
// TIPOS PARA FILTROS
// ============================================

/**
 * Filtros para licencias
 */
export interface LicenseFilters {
  status?: LicenseStatus;
  type?: LicenseType;
  client_id?: string;
  product_id?: string;
  expired?: boolean;
}

// ============================================
// CONSTANTES
// ============================================

/**
 * Etiquetas legibles para roles
 */
export const ROLE_LABELS: Record<UserRole, string> = {
  admin: 'Administrador',
  staff: 'Personal'
};

/**
 * Etiquetas legibles para tipos de licencia
 */
export const LICENSE_TYPE_LABELS: Record<LicenseType, string> = {
  licencia_unica: 'Licencia Única',
  suscripcion: 'Suscripción'
};

/**
 * Etiquetas legibles para estados de licencia
 */
export const LICENSE_STATUS_LABELS: Record<LicenseStatus, string> = {
  activa: 'Activa',
  inactiva: 'Inactiva',
  pendiente_pago: 'Pendiente de Pago'
};

/**
 * Colores para badges de estado
 */
export const LICENSE_STATUS_COLORS: Record<LicenseStatus, string> = {
  activa: 'green',
  inactiva: 'gray',
  pendiente_pago: 'yellow'
};
