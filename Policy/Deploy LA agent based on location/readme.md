# Deploy Log Analytics Agent based on a central monitoring architecture, per location

Problem: Built-In Azure Policy is will assign the same workspace to all resources at the assignment scope. In the case that an organization has location based logging (one workspace for Region A, another for Region B, etc.), they can use this custom policy to assign workspaces based on location.
