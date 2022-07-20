# Deploy and Update Policy (Guest Configuration) extension on VMs

Two policies defined to attach to supported Windows and Linux Azure VMs.
The policies audit the "enableAutomaticUpgrade" attribute to be enabled and sets the "Force update tag" as string value provided by a parameter.

Once the "Force update tag" changes its value, the extension is considered changed, which triggers the autoupgrade process


