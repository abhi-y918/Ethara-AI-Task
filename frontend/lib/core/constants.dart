// Base URL for the FastAPI backend
// Change this to your Railway URL in production
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000',
);

const String kApiPrefix = '$kApiBaseUrl/api';

// Secure storage keys
const String kTokenKey = 'access_token';

// Route names
const String kRouteLogin = '/login';
const String kRouteSignup = '/signup';
const String kRouteDashboard = '/dashboard';
const String kRouteProjects = '/projects';
const String kRouteProjectDetail = '/projects/:id';
const String kRouteTaskDetail = '/tasks/:id';
