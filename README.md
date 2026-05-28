# mac-bootstrap

One-shot Mac pentest workstation setup for Apple Silicon.

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Tannahsheen/mac-bootstrap/main/install.sh)
```

## What it installs

### Recon / Scanning
`nmap` `masscan` `rustscan` `ffuf` `feroxbuster` `gobuster` `nikto` `nuclei` `amass` `subfinder`

### AD / Internal Pentest
`netexec` `impacket` `kerbrute` `evil-winrm` `certipy-ad` `enum4linux-ng` `ldapdomaindump` `mitm6` `responder` `bloodhound-py`

### Exploitation / Post
`metasploit` `hydra` `patator` `sqlmap` `john-jumbo` `hashcat` `rlwrap` `proxychains-ng`

### Network
`bettercap` `wireshark` `zaproxy` `smbclient` `ldap-utils`

### Ligolo-ng + Gowitness
Binary downloads — latest release, auto-detected Apple Silicon vs Intel.

### ~/tools
| Tool | Purpose |
|------|---------|
| SecLists | Wordlists |
| PetitPotam | Coercion |
| DFSCoerce | Coercion |
| ShadowCoerce | Coercion |
| Responder | LLMNR/NBT-NS poisoning |
| BloodHound CE | AD attack paths (docker) |

### Apps
`iTerm2` `AeroSpace` `Sublime Text` `Docker Desktop` `Wireshark` `OWASP ZAP` `Hack Nerd Font`

### Commercial (detected, not installed)
Parallels · Microsoft Office · Claude · ClickUp

## Dotfiles

Clones [Tannahsheen/mac-dotfiles](https://github.com/Tannahsheen/mac-dotfiles) and runs `install.sh` automatically.

## After running

```bash
brew services start sketchybar
open -a AeroSpace
# Start Docker Desktop, then BloodHound CE:
docker compose -f ~/tools/BloodHound-CE/examples/docker-compose/docker-compose.yml up -d
# BloodHound CE → http://localhost:8080
```

> **Note:** Responder and mitm6 have limited functionality on macOS due to raw socket restrictions.
> Use a Linux/Kali box for LLMNR poisoning in real engagements.
