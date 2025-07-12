# DNS Troubleshooting with dig

## The dig Command

The dig command (Domain Information Groper) is a powerful DNS lookup tool used to query DNS servers and troubleshoot DNS-related issues. It's the modern replacement for older tools like nslookup.

## Purpose of dig

- **Retrieve DNS records** for any domain
- **Test DNS name resolution** and verify configurations
- **Diagnose DNS configuration problems** and connectivity issues
- **Query specific DNS servers** directly
- **Trace DNS resolution path** through the hierarchy
- **Debug zone transfers** and DNSSEC validation

## Basic Syntax

```bash
dig [@server] [name] [type] [options]
```

### Parameters Explained

**@server** (optional):
- The DNS server to query
- Examples: `@8.8.8.8` (Google DNS), `@1.1.1.1` (Cloudflare)
- If omitted, uses system's default DNS servers

**name**:
- The domain name you want to query
- Examples: `example.com`, `www.google.com`

**type**:
- The type of DNS record to query
- Common types: `A`, `AAAA`, `MX`, `NS`, `TXT`, `SOA`, `CNAME`, `ANY`
- If omitted, defaults to `A` record

## Common dig Options

### Output Formatting
- **`+short`** - Gives concise output (just the answer)
- **`+noall +answer`** - Shows only the answer section (useful for scripts)
- **`+multiline`** - Pretty-prints records in multiple lines
- **`+yaml`** - Output in YAML format

### Tracing and Debugging
- **`+trace`** - Shows the complete path of DNS resolution from root servers to authoritative servers
- **`+nssearch`** - Searches for all authoritative nameservers for a zone
- **`+nocmd`** - Don't print the initial command line
- **`+nocomments`** - Don't print comment lines
- **`+nostats`** - Don't print query statistics

### Query Behavior
- **`+tcp`** - Use TCP instead of UDP
- **`+tries=N`** - Set number of retry attempts
- **`+time=N`** - Set query timeout in seconds
- **`+recurse`** / **`+norecurse`** - Enable/disable recursive queries

## Common dig Commands

### Basic Record Queries
```bash
# Query A record (default)
dig example.com

# Query specific record types
dig example.com MX
dig example.com NS
dig example.com TXT
dig example.com SOA
dig example.com AAAA

# Query all records
dig example.com ANY
```

### Using Specific DNS Servers
```bash
# Query Google DNS
dig @8.8.8.8 example.com

# Query Cloudflare DNS
dig @1.1.1.1 example.com

# Query domain's own nameserver
dig @ns1.example.com example.com
```

### Short and Clean Output
```bash
# Just the IP address
dig +short example.com

# Just the MX records
dig +short example.com MX

# Clean answer only
dig +noall +answer example.com
```

### Reverse DNS Lookups
```bash
# Reverse lookup for IP address
dig -x 8.8.8.8

# Reverse lookup with short output
dig +short -x 192.0.2.1
```

### Tracing DNS Resolution
```bash
# Trace complete resolution path
dig +trace example.com

# Trace specific record type
dig +trace example.com MX

# Trace with short output
dig +trace +short example.com
```

## The Lifecycle of DNS Resolution

Understanding how DNS resolution works helps in troubleshooting DNS issues.

### Step 1: Client Initiates Query
Your device, acting as a **stub resolver**, sends a request to find the IP address of a domain name.

### Step 2: Local DNS Cache Check
The device first checks its own local DNS cache to see if it already has the IP address stored from a recent visit.
- **Cache Hit:** If found, responds quickly from cache
- **Cache Miss:** Proceeds to next step

### Step 3: Recursive Resolver Query
If the IP address is not in the local cache, the request is sent to a recursive resolver:
- Typically provided by your Internet Service Provider (ISP)
- Or third-party services like Google DNS (8.8.8.8) or Cloudflare (1.1.1.1)
- The recursive resolver also maintains its own cache
- **Cache Hit:** If it has the answer, returns it to the client
- **Cache Miss:** Begins iterative queries on behalf of the client

### Step 4: Iterative Queries to Authoritative Servers
The recursive resolver performs a series of iterative queries to navigate the DNS hierarchy:

#### Root Server Query
- The recursive resolver first queries a root DNS server
- Root server responds with referral to the appropriate TLD server
- Example: For `www.example.com`, referred to `.com` TLD servers

#### TLD Server Query
- Resolver queries the TLD server (e.g., `.com` server)
- TLD server responds with referral to authoritative nameserver for the domain
- Example: Referred to nameservers for `example.com`

#### Authoritative Name Server Query
- Resolver queries the authoritative DNS server for the domain
- This server holds the actual DNS records (resource records) for that domain as a DNS zone
- Authoritative server provides the IP address or other requested information

### Step 5: Handling Glue Records
When a domain's authoritative nameserver is a subdomain of the domain itself:
- **Problem:** Circular dependency (need `example.com` to find `ns1.example.com`)
- **Solution:** Glue records (IP addresses of nameservers) provided by parent zone
- **Purpose:** Allows resolver to find the nameserver's IP address for initial lookup

### Step 6: Caching and Response
- The recursive resolver caches the received resource record for the specified TTL duration
- Improves performance for future queries to the same domain
- Sends the IP address back to the client

### Step 7: Website Loads
- Client's browser uses the received IP address to connect to the web server
- Website loads using the resolved IP address

## Troubleshooting with dig

### Common DNS Problems and Solutions

#### Problem: Domain Not Resolving
```bash
# Check if domain exists
dig example.com

# Check with different DNS servers
dig @8.8.8.8 example.com
dig @1.1.1.1 example.com

# Check authoritative servers
dig example.com NS
dig @ns1.example.com example.com
```

#### Problem: Slow DNS Resolution
```bash
# Trace resolution path
dig +trace example.com

# Check query times to different servers
dig @8.8.8.8 example.com
dig @local.dns.server example.com

# Test with TCP (sometimes faster for large responses)
dig +tcp example.com
```

#### Problem: Email Issues
```bash
# Check MX records
dig example.com MX

# Verify SPF records
dig example.com TXT | grep spf

# Check DMARC policy
dig _dmarc.example.com TXT
```

#### Problem: Subdomain Issues
```bash
# Check subdomain resolution
dig subdomain.example.com

# Verify delegation
dig subdomain.example.com NS

# Check if wildcard is configured
dig nonexistent.example.com
```

### Advanced Troubleshooting Techniques

#### Compare Nameserver Responses
```bash
# Check consistency between nameservers
dig @ns1.example.com example.com SOA
dig @ns2.example.com example.com SOA

# Look for serial number mismatches
dig @ns1.example.com example.com SOA +short
dig @ns2.example.com example.com SOA +short
```

#### Verify DNS Propagation
```bash
# Check root servers
dig @a.root-servers.net example.com NS

# Check TLD servers
dig @a.gtld-servers.net example.com NS

# Compare with what registrar shows
whois example.com | grep "Name Server"
```

#### Test DNSSEC
```bash
# Check DNSSEC status
dig example.com +dnssec

# Verify DNSSEC chain
dig +trace +dnssec example.com
```

## Practical dig Examples

### Website Migration Verification
```bash
# Before migration - record current IP
dig +short example.com > before.txt

# After migration - check new IP
dig +short example.com > after.txt

# Compare results
diff before.txt after.txt

# Check propagation across different servers
dig @8.8.8.8 +short example.com
dig @1.1.1.1 +short example.com
dig @208.67.222.222 +short example.com  # OpenDNS
```

### Email Configuration Validation
```bash
# Complete email DNS check
dig example.com MX
dig example.com TXT | grep -E "(spf|dmarc)"
dig _dmarc.example.com TXT
dig selector1._domainkey.example.com TXT
```

### Performance Analysis
```bash
# Time multiple queries
time dig example.com >/dev/null
time dig @8.8.8.8 example.com >/dev/null
time dig @1.1.1.1 example.com >/dev/null

# Check response times in dig output
dig example.com | grep "Query time"
```

## Useful dig Scripts

### Quick Domain Health Check
```bash
#!/bin/bash
DOMAIN=$1
echo "=== DNS Health Check for $DOMAIN ==="
echo "A Record: $(dig +short $DOMAIN)"
echo "MX Records: $(dig +short $DOMAIN MX)"
echo "NS Records: $(dig +short $DOMAIN NS)"
echo "SOA Record: $(dig +short $DOMAIN SOA)"
```

### Check Nameserver Consistency
```bash
#!/bin/bash
DOMAIN=$1
for ns in $(dig +short $DOMAIN NS); do
    echo "Checking $ns:"
    dig @$ns +short $DOMAIN SOA
done
```

## Best Practices

1. **Use +short for scripting** - Makes parsing output easier
2. **Always check multiple nameservers** - Ensures consistency
3. **Use +trace for complex issues** - Shows full resolution path
4. **Test with different DNS servers** - Identifies server-specific issues
5. **Check TTL values** - Understanding caching behavior
6. **Verify DNSSEC when applicable** - Ensures security compliance
7. **Document your findings** - Keep troubleshooting logs for future reference
