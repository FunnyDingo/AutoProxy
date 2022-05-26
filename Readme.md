# Set-Proxy.ps1
If you use your device in different networks with different proxy configurations, setting up a proxy for all the applications can be a pain. This small script supports you, to do this automatically.

Depending on the Windows NLA (Network Location Awareness), the script sets the proxy for different applications for you.

# Preperation
Create a scheduled tasks (the `Set Proxy - User.xml`) to run the script when
- you logon
- everytime the network locations changes

# Configuration
Configuration is done via a JSON file. The `ProxyConfig.example.json` in this repository.

The top level item is the location. This name must match the name of location used by Windows NLA. The location *default* is used, if no matching location has been found.

The second configuration level is the scope. Currently this is fix *user*, the section `Why 'user'?`.

In the third level you configuration the "application". The script support these ones:

## env
`env` is used for the Windows environment. The values here are used to set the envirnment variables http_proxy, https_proxy and no_proxy.

A emtpy strings means to unset the variable.

## git
To understand this example better, let me explain a .gitconfig related to proxy:
```
[http]
    proxy = "http://localhost:3128"
[http "https://someserver.domain.internal"]
    proxy = ""
```
In the first line, the section *http* is started. The proxy value here means: use this *general proxy* for all communication.

In the third line the section *[http "https://someserver.domain.internal"]* is started. With this syntax, Git allows you to configure a divergent configuration for this host.

The `ProxyConfig.json` follows the same logic. In line 9 of the exmaple, the *general proxy* is set, while in the lines 10 & 11 a different proxy for exactly this host is set.

If the `.gitconfig` file includes a proxy setting for a host not configured in the `ProxyConfig.json`, the proxy for that host is set to the *general proxy* as well.

**Important:**

The script only changes existing entries! It never adds or removes sections.

For example: if you remove the host configuration for *https://someserver.domain.internal* from your `.gitconfig` but keep it in the `ProxyConfig.json`, the script wouldn't add a section for this host! It just ignores this setting.

# Why 'user'?
In the `ProxyConfig.json` the keyword *user* is used. Also in the script you find the "RunMode" / scope.

The script as started as a dual config tool: user and machine configuration should be managed by it. The idea was, that the config file can include configurations set in the current user or the machine context (for example system wide environment variables or system wide application config files).

But due to some security concerns and the realization that this is not really necessary, the "machine" part got more and more useless.

Maybe the need comes back sometime, so I decided to keep that "preperation".
