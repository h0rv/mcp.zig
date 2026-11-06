// Local verification policy. Never access the host keychain or remote services in tests.
// A runtime value keeps the disabled test body type-checked.
pub var host_integrations: bool = false;
