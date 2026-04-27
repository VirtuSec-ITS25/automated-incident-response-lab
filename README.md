# Automated Incident Response Lab

> Kort beskrivning av vad projektet gör — en eller två meningar. Exempel: \*En automatiserad infrastruktur med en lastbalanserad Flask-webbapplikation driftsatt på två separata VMs via Ansible, med en isolerad PostgreSQL-databasserver.\*
---
Innehållsförteckning
Arkitektur
Miljöer och IP-adresser
Mappstruktur
Komponenter
Krav och förutsättningar
Kom igång
Secrets
Säkerhetsåtgärder
Säkerhetsanalys
Verifiering
Designval och motivering
---
Arkitektur
> \*\*Instruktion:\*\* Lägg in ett arkitekturdiagram här. Du kan använda något av följande alternativ:
>
> - \*\*draw.io / diagrams.net\*\* — exportera som PNG och lägg filen i `docs/architecture.png`, referera sedan med bildsyntaxen nedan
> - \*\*draw.io XML\*\* — spara filen som `docs/architecture.drawio` (kan öppnas och redigeras direkt på GitHub)
> - \*\*ASCII-diagram\*\* — rita direkt i Markdown om du föredrar det, se exemplet nedan
>
> Ta bort denna instruktionsruta när du är klar.
<!-- Alternativ 1: Bild exporterad från draw.io -->
<!-- !\[Arkitekturdiagram](docs/architecture.png) -->
<!-- Alternativ 2: ASCII-diagram (ersätt med din faktiska topologi) -->
```
Windows-laptop (host)
        |
        | :8080 (port forwarding)
        |
┌───────▼──────────────────────────────────┐
│           Privat nätverk 192.168.56.0/24  │
│                                           │
│  ┌─────────────────────┐                  │
│  │   nginx (lb)        │                  │
│  │   192.168.56.10     │                  │
│  └────────┬────────────┘                  │
│           │ round-robin                   │
│     ┌─────┴──────┐                        │
│     ▼            ▼                        │
│  ┌──────┐    ┌──────┐                     │
│  │ web1 │    │ web2 │                     │
│  │ .11  │    │ .12  │                     │
│  └──┬───┘    └──┬───┘                     │
│     └─────┬─────┘                         │
│           ▼                               │
│  ┌─────────────────────┐                  │
│  │   database          │                  │
│  │   192.168.56.13     │  UFW: port 5432  │
│  │   (ej port fwd)     │  endast från .11 │
│  └─────────────────────┘  och .12         │
└──────────────────────────────────────────┘
```
---
Miljöer och IP-adresser
VM	Roll	IP-adress	Port forwarding	Beskrivning
`nginx`	Lastbalanserare	192.168.56.10	`:80 → host:8080`	nginx tar emot all inkommande trafik och fördelar den
`web1`	Applikationsserver	192.168.56.11	—	Flask + Gunicorn, hanteras av systemd
`web2`	Applikationsserver	192.168.56.12	—	Flask + Gunicorn, hanteras av systemd
`database`	Databasserver	192.168.56.13	—	PostgreSQL, lyssnar enbart på det privata nätverket
---
Mappstruktur
```
repo/
├── vagrant/
│   ├── Vagrantfile          # Definierar alla VMs och nätverksinställningar
│   └── secrets.yml          # GITIGNORERAD — lösenord och känsliga värden
│
├── ansible/
│   ├── ansible.cfg          # Ansible-konfiguration (inventory, remote\_user, osv)
│   ├── inventory.ini        # Vilka servrar Ansible hanterar och i vilka grupper
│   ├── site.yml             # Master playbook — kör alla roller i rätt ordning
│   ├── secrets\_example.yml  # Mall för secrets.yml (inga riktiga värden)
│   │
│   ├── vars/
│   │   └── main.yml         # Delade variabler (IP-adresser, portar, sökvägar)
│   │
│   └── roles/
│       ├── flask/           # Driftsätter Flask-applikationen
│       │   ├── tasks/
│       │   │   └── main.yml
│       │   ├── handlers/
│       │   │   └── main.yml
│       │   ├── templates/
│       │   │   └── flask.service.j2
│       │   ├── files/
│       │   │   ├── app.py
│       │   │   └── requirements.txt
│       │   └── defaults/
│       │       └── main.yml
│       │
│       ├── nginx/           # Installerar och konfigurerar nginx som lastbalanserare
│       │   ├── tasks/
│       │   │   └── main.yml
│       │   ├── handlers/
│       │   │   └── main.yml
│       │   └── templates/
│       │       └── nginx.conf.j2
│       │
│       └── database/        # Installerar PostgreSQL och sätter upp databas och användare
│           ├── tasks/
│           │   └── main.yml
│           ├── handlers/
│           │   └── main.yml
│           └── templates/
│               └── pg\_hba.conf.j2
│
├── docs/
│   └── architecture.png     # Arkitekturdiagram (exporterat från draw.io)
│
├── .gitignore
└── README.md
```
---
Komponenter
Vagrantfile
Definierar fyra virtuella maskiner i VirtualBox med ett gemensamt host-only-nätverk (`192.168.56.0/24`). Port forwarding på nginx-VM:en (`80 → 8080`) gör att webbapplikationen är nåbar från Windows-hosten. Databasservern har medvetet ingen port forwarding — den är inte nåbar utifrån.
ansible.cfg
Pekar på `inventory.ini`, sätter `remote\_user = vagrant`, inaktiverar host key checking (lämpligt i labbmiljö) och anger att roller finns i `roles/`-katalogen.
inventory.ini
Grupperar servrarna i `\[nginx]`, `\[webservers]` och `\[database]`. Nginx-templaten i nginx-rollen använder `groups\["webservers"]` för att dynamiskt generera upstream-blocket — nya servrar kan läggas till utan att ändra nginx-konfigurationen manuellt.
site.yml
Master playbook med tre plays som körs i ordning:
database — konfigureras först så att anslutningsuppgifterna är klara
webservers — Flask-rollen installerar Python, venv, paket och systemd-tjänst
nginx — konfigureras sist, efter att webbservrarna är uppe
Rollen flask
Installerar Python 3, skapar ett virtual environment under `/opt/flask/venv`, installerar beroenden från `requirements.txt`, kopierar `app.py` och installerar en systemd-tjänst som startar Gunicorn. Tjänsten konfigureras med `Restart=always` och tar emot konfiguration via miljövariabler (`PORT`, `DB\_HOST`, `DB\_PASSWORD`).
Rollen nginx
Installerar nginx och renderar `nginx.conf.j2` med ett `upstream`-block som itererar över alla servrar i `\[webservers]`-gruppen. Konfigurerar `proxy\_pass` och vidarebefordrar relevanta HTTP-headers.
Rollen database
Installerar PostgreSQL, skapar databasen och en applikationsanvändare med begränsade behörigheter (enbart `SELECT`, `INSERT`, `UPDATE` på relevanta tabeller). Konfigurerar `pg\_hba.conf` för att enbart tillåta anslutningar från webservrarnas IP-adresser och aktiverar UFW som blockerar port 5432 från alla utom `192.168.56.11` och `192.168.56.12`.
Flask-applikationen (app.py)
En enkel Flask-applikation med tre endpoints:
Endpoint	Metod	Beskrivning
`/`	GET	Returnerar ett välkomstmeddelande med serverns hostname
`/info`	GET	Returnerar JSON med hostname, timestamp och konfiguration
`/health`	GET	Health check — används av nginx för att avgöra om servern är uppe
All konfiguration (port, databasuppgifter) läses från miljövariabler via `os.environ.get()`.
---
Krav och förutsättningar
Programvara som måste vara installerad på Windows-hosten:
VirtualBox — testat med version 7.x
Vagrant — testat med version 2.x
Git
Hårdvarukrav:
Minst 8 GB RAM (projektet använder totalt ~2 GB)
Minst 20 GB ledigt diskutrymme
Secrets-fil:
Skapa filen `vagrant/secrets.yml` baserat på mallen `ansible/secrets\_example.yml` innan du kör `vagrant up`. Se avsnittet Secrets.
---
Kom igång
```bash
# 1. Klona repot
git clone git@github.com:dittanvandarnamn/ansible-lab.git
cd ansible-lab

# 2. Skapa secrets-filen (se avsnittet Secrets nedan)
cp ansible/secrets\_example.yml vagrant/secrets.yml
# Redigera vagrant/secrets.yml med riktiga värden

# 3. Starta alla VMs
cd vagrant
vagrant up

# 4. SSH in på kontrollnoden (om du har en) eller kör Ansible direkt
vagrant ssh control

# 5. Kör playbooken
cd \~/ansible-lab/ansible
git pull
ansible-playbook site.yml -v

# 6. Verifiera att allt fungerar
bash test/verify.sh
```
Förväntat slutresultat:
Öppna `http://localhost:8080/info` i webbläsaren. Du ska se JSON med `"hostname": "web1"` eller `"hostname": "web2"` — värdena ska växla vid upprepade anrop (round-robin lastbalansering).
---
Secrets
Filen `vagrant/secrets.yml` måste skapas lokalt och ska aldrig committas till Git (den finns i `.gitignore`).
Kopiera mallen och fyll i riktiga värden:
```bash
cp ansible/secrets\_example.yml vagrant/secrets.yml
```
Filen är tillgänglig på kontrollnoden som `/vagrant/secrets.yml` via Vagrants delade mapp och refereras i playbooken med:
```yaml
vars\_files:
  - /vagrant/secrets.yml
  - vars/main.yml
```
Se `ansible/secrets\_example.yml` för vilka variabler som krävs.
---
Säkerhetsåtgärder
Följande säkerhetsåtgärder är implementerade och automatiserade via Ansible:
Åtgärd	Var	Hur verifieras det
SSH root-inloggning inaktiverad	Alla VMs	`sshd -T | grep permitrootlogin`
Lösenordsautentisering via SSH inaktiverad	Alla VMs	`sshd -T | grep passwordauthentication`
UFW brandvägg aktiv	Databas-VM	`sudo ufw status verbose`
Port 5432 blockerad utifrån	Databas-VM	`Test-NetConnection 192.168.56.13 -Port 5432` från Windows
Port 5432 tillgänglig från webservers	Databas-VM	`nc -zv 192.168.56.13 5432` från web1/web2
Databasanvändare med minsta privilegium	Databas-VM	`\\du` i psql
Secrets utanför Git	Alla	`git log --all -- vagrant/secrets.yml` (tom output)
Flask körs som icke-root	Webservers	`ps aux | grep gunicorn`
---
Säkerhetsanalys
> \*\*Instruktion:\*\* Beskriv kvarvarande säkerhetsbrister i miljön och vad som skulle behövas för att åtgärda dem. Det är inte ett problem att ha brister — alla system har det. Det viktiga är att du förstår vad de är och kan motivera varför de accepteras i denna miljö eller vad som krävs för att åtgärda dem. Ta bort denna instruktionsruta när du är klar.
Kvarvarande brister
Brist 1: Okrypterad kommunikation mellan nginx och Flask
Trafiken mellan nginx och Flask-servrarna är okrypterad HTTP. En angripare med tillgång till det interna nätverket kan läsa eller manipulera trafiken.
Åtgärd: Konfigurera TLS med ett internt CA-certifikat för kommunikationen på det privata nätverket, alternativt använda ett overlay-nätverk som WireGuard.
Accepterat i denna miljö eftersom: Det privata nätverket (`192.168.56.0/24`) är isolerat från internet och enbart tillgängligt från värddatorn. Risken bedöms som låg i labbmiljö.
---
Brist 2: Databaslösenord synligt i systemd-miljö
Databaslösenordet sätts via `Environment=` i systemd unit-filen och är synligt i `/proc/<pid>/environ` för root. Det loggas potentiellt i systemd-journal vid felsökning.
Åtgärd: Använda en dedicated secrets manager (HashiCorp Vault) eller systemd:s `EnvironmentFile=` med en fil med begränsade läsrättigheter (`chmod 600`, ägd av tjänsteanvändaren).
Accepterat i denna miljö eftersom: Åtkomst till `/proc` kräver root-behörighet. I en labbmiljö utan externa angripare bedöms risken som acceptabel.
---
Brist 3: Ingen intrångsdetektering (IDS)
Det finns ingen övervakningslösning som larmar vid ovanlig aktivitet — t.ex. upprepade misslyckade inloggningsförsök eller ovanliga nätverksanslutningar.
Åtgärd: Installera Wazuh-agent på alla VMs och konfigurera en Wazuh Manager för centraliserad logganalys och larmregler.
---
Vad som skyddar miljön
Trots ovanstående brister har miljön följande skyddslager:
Nätverkssegmentering: databasen är inte nåbar utifrån
Brandvägg (UFW) på databasservern med explicit allow-regler
Principen om minsta privilegium på databasnivå
Inga lösenord i versionshanteringen
---
Verifiering
Kör det automatiserade verifieringsskriptet från kontrollnoden:
```bash
bash ansible/test/verify.sh
```
Skriptet kontrollerar:
Att alla VMs svarar på ping
Att Flask körs på web1 och web2
Att `/health`-endpointen returnerar HTTP 200
Att lastbalansering fungerar (båda hostnames förekommer vid upprepade anrop)
Att databasservern INTE svarar på port 5432 från kontrollnoden (UFW fungerar)
Att webservrarna KAN nå databasen på port 5432
Förväntat output:
```
================================
 Verifiering av infrastruktur
================================
✓ web1 svarar på ping
✓ web2 svarar på ping
✓ database svarar på ping
✓ Flask körs på web1
✓ Flask körs på web2
✓ Health check web1: HTTP 200
✓ Health check web2: HTTP 200
✓ Lastbalansering: web1 och web2 förekommer båda
✓ UFW blockerar port 5432 från kontrollnoden
✓ web1 kan nå databasen på port 5432
✓ web2 kan nå databasen på port 5432
================================
 Resultat: 11 godkända, 0 misslyckade
================================
```
---
Designval och motivering
> \*\*Instruktion:\*\* Förklara de viktigaste arkitekturval du gjort och varför. Det finns inga rätta svar — det viktiga är att du kan motivera dina val. Ta bort denna instruktionsruta när du är klar.
Varför separata VMs för webserver och databas?
Att köra Flask och PostgreSQL på samma VM hade förenklat uppläget men eliminierat nätverkssegmenteringen. Om webbservern komprometteras skulle en angripare ha direkt lokal åtkomst till databasen utan att behöva passera något nätverkslager. Med separata VMs krävs åtminstone en nätverksanslutning mot databasservern, vilket UFW-reglerna begränsar.
Varför Gunicorn framför Flasks inbyggda server?
Flasks inbyggda server (`app.run()`) är enkeltrådig och hanterar en förfrågan i taget. I en miljö med lastbalansering är det viktigt att varje server kan hantera parallella förfrågningar. Gunicorn kör flera worker-processer och är den etablerade standarden för Flask i produktion.
Varför Jinja2-template för nginx.conf istället för en statisk fil?
`upstream`-blocket i nginx-konfigurationen genereras dynamiskt från `groups\["webservers"]` i Ansible-inventory. Det innebär att om en tredje webbserver läggs till i inventory uppdateras nginx-konfigurationen automatiskt nästa gång playbooken körs — utan manuell redigering av nginx.conf.
Varför virtual environment istället för global pip-installation?
Global pip-installation riskerar konflikter med systemets Python-paket och gör det svårt att ha olika versioner av paket för olika projekt på samma server. Virtual environments isolerar varje projekts beroenden och gör det möjligt att återskapa exakt samma milj ö på en ny server via `pip install -r requirements.txt`.
---
Skapad av: [Ditt namn]  
Kurs: Virtualiseringsteknik  
Datum: [ÅÅÅÅ-MM-DD]
