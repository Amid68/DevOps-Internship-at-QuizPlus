# DNS Fundamentals

## What is DNS?

DNS (Domain Name System) acts as the internet's phone book, translating human-readable domain names into IP addresses. It solves the problem of remembering numerical IP addresses by providing memorable domain names and functions as a distributed translation service that operates in milliseconds.

## DNS Structure

DNS is structured as a hierarchical and distributed name service, similar to a phonebook for the internet. The DNS namespace is a tree-like data structure, with each node or leaf having a label and associated resource records.

### Key Characteristics
- **Case-independent:** Domain names are not case-sensitive
- **Length limit:** Complete domain names including all labels separated by dots can't exceed 253 characters
- **Distributed:** No single point of failure
- **Hierarchical:** Authority flows downward through delegation

## DNS Hierarchy Levels

### Root Level
- **Symbol:** Single dot (.) at the very end of a domain name
- **Management:** DNS root zone is managed by 13 authoritative root name server clusters worldwide using anycast
- **Purpose:** Origin of the DNS hierarchy

### Top-Level Domains (TLDs)
Well-known domain names that appear below the root level:

**Generic TLDs (gTLDs):**
- `.com` - Commercial organizations
- `.org` - Organizations
- `.net` - Network infrastructure
- `.edu` - Educational institutions
- `.gov` - Government agencies
- `.mil` - Military

**Country-Specific TLDs (ccTLDs):**
- `.us` - United States
- `.uk` - United Kingdom
- `.es` - Spain
- `.de` - Germany
- `.ps` - Palestine

### Second-Level Domains (SLDs)
- Located directly beneath TLDs
- Example: `example.com` (where "example" is the second-level domain)
- Managed through domain registrars
- Can have compound forms: `.co.uk`, `.ac.uk`

### Third-Level Domains / Subdomains
- Example: `blog.example.com` (where "blog" is a subdomain of example.com)
- `www` is commonly used as a subdomain
- Infinite flexibility below second-level domains

### Hosts
- The host section of a fully qualified domain name (FQDN) identifies a particular device, often a dedicated server
- A device name with an A (Address) record in DNS has at least one associated IP address

## DNS Zone Concepts

### DNS Zones
An administrative area within the DNS hierarchy that contains all the DNS records for a specified portion of the domain name space. Zone files are text files stored on servers containing these records.

### DNS Zone Transfer
A communication method between a primary (master) DNS server and secondary (slave) DNS servers, where a copy of the DNS zone database is transferred to keep secondary servers up-to-date. This process typically uses TCP port 53 to ensure consistency.

### DNS Propagation
The time it takes for DNS changes or updates to spread across the entire DNS network and become globally accessible. This is heavily influenced by the TTL (Time to Live) values of records.

## Local DNS Infrastructure

### What is Local DNS?
The part of DNS infrastructure that operates closely to the end user or within an organization's private network, as opposed to the global public DNS hierarchy.

### Components

**Client-side DNS Cache:**
- Every device maintains a local DNS cache
- Temporarily stores results of recent DNS queries
- First source checked when resolving domain names

**Internal DNS Servers (Private DNS):**
- Operates within organizations for internal networks
- Keeps internal addresses hidden from external internet
- Provides local domain resolution

**DNS Resolvers:**
- ISP or public servers (8.8.8.8, 1.1.1.1) handle queries for clients
- Maintain extensive caches for performance

**Router Role:**
- Acts as local DNS server for home networks
- Maintains its own cache
- Forwards queries to upstream resolvers

### Benefits of Local DNS

**Performance:**
- Increased speed and reduced latency
- Multiple levels of caching minimize query times
- Reduced DNS server load

**Reliability:**
- Improved operational resilience
- Redundancy at multiple levels

**Security:**
- Hiding internal network information
- Content filtering capabilities
- Attack mitigation
- DNS queries can reveal browsing activity (encryption available via DoH/DoT)

**Control:**
- Organizations control their own DNS infrastructure
- Users can choose DNS providers for speed, security, or privacy

## DNS Query Types

### Recursive vs Iterative DNS

**Recursive Queries:**
- Client delegates entire resolution task to resolver
- Gets final answer from resolver
- Most end-user queries are recursive
- Requires trust in resolver

**Iterative Queries:**
- Client maintains control
- Follows referrals step-by-step through hierarchy
- Infrastructure typically uses iterative queries
- Offers more control over the resolution process

**Division of Labor:**
- End users make recursive queries to resolvers
- Resolvers perform iterative queries through the DNS hierarchy

## DNS Redundancy and Reliability

### Failure Handling
- Multiple servers at every level prevent single points of failure
- Anycast routing automatically directs queries to closest available servers
- Caching at multiple levels provides resilience during server failures
- Geographic distribution enables load balancing and disaster recovery

### Monitoring and Maintenance
- Automatic monitoring and failover systems detect and resolve issues
- TTL values balance performance with data freshness
- Layered caching: personal cache → ISP resolver cache → global infrastructure

## Key System Benefits

**Scalability:** Distributed load across thousands of servers globally

**Performance:** Multiple levels of caching and strategic positioning minimize query times

**Reliability:** Redundancy at every level ensures continuous operation

**Flexibility:** Organizations control their own DNS infrastructure

**Security:** Modern extensions (DNSSEC, DoH, DoT) add cryptographic validation and privacy

**Efficiency:** Hierarchical structure prevents any single server from being overwhelmed
