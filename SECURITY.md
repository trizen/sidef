# Security Policy for Sidef

This is the Security Policy for the **Sidef** programming language and its CPAN distribution (`Sidef`).

Report security vulnerabilities via the [GitHub Security Advisories](https://github.com/trizen/sidef/security/advisories)
page for this project.

The latest version of this Security Policy can be found in the
[git repository for Sidef](https://github.com/trizen/sidef/blob/master/SECURITY.md).

This text is based on the CPAN Security Group's Guidelines for Adding a Security Policy
to Perl Distributions (version 1.4.2):
<https://security.metacpan.org/docs/guides/security-policy-for-authors.html>

---

## How to Report a Security Vulnerability

Security vulnerabilities can be reported via the project's GitHub repository
[Security Advisories](https://github.com/trizen/sidef/security/advisories).
On the "Advisories" page, click the **"Report a vulnerability"** button to open
a private, confidential report.

Please include as many details as possible, including:

- A clear description of the vulnerability.
- Code samples or test cases that reproduce the issue.
- The version(s) of Sidef affected.
- Any relevant environment details (operating system, Perl version, etc.).

Please ensure your report does not expose sensitive data such as passwords,
tokens, or personal information.

The project maintainer will normally credit the reporter when a vulnerability is
disclosed or fixed. If you do not wish to be credited publicly, please indicate
that in your report.

If you would like help triaging the issue, or if the issue is being actively
exploited, please also copy your report to the **CPAN Security Group (CPANSec)**
at <cpan-security@security.metacpan.org>.

**Please do NOT use the public GitHub Issues tracker** to report security
vulnerabilities, as this will disclose the issue publicly before a fix is ready.

Please do not disclose the security vulnerability in public forums until a fix
has been released or it has been made public by the maintainer or CPANSec. This
includes patches, pull requests, or mitigation advice.

For more information, see [Report a Security Issue](https://security.metacpan.org/docs/report.html)
on the CPANSec website.

### Response to Reports

The maintainer aims to acknowledge your security report as soon as possible.
However, Sidef is maintained by a single volunteer in their spare time, and a
rapid response cannot be guaranteed. If you have not received a response within
**one week (7 days)**, please send a reminder to the maintainer and copy the
report to CPANSec at <cpan-security@security.metacpan.org>.

Please note that the initial response to your report will be an acknowledgement,
with a possible request for more information. It will not necessarily include any
fixes for the issue.

The project maintainer may forward this issue to the security contacts for other
projects where it is believed to be relevant. This may include embedded
libraries, system libraries, prerequisite modules, or downstream software that
uses Sidef.

They may also forward this issue to CPANSec.

---

## Which Software This Policy Applies To

Any security vulnerabilities in **Sidef** (the programming language interpreter,
compiler, and standard library distributed via CPAN as `Sidef`) are covered by
this policy.

Security vulnerabilities in versions of any libraries or modules that are
bundled with Sidef are also covered by this policy.

**Security vulnerabilities are considered** anything that allows users to:

- Execute unauthorised code,
- Access unauthorised resources,
- Have an adverse impact on the accessibility, integrity, or performance of a
  system.

Security vulnerabilities in **upstream software** (prerequisite CPAN modules,
system libraries, or Perl itself) are **not** covered by this policy, unless
they directly affect Sidef or Sidef can be used to exploit them.

Security vulnerabilities in **downstream software** (any software that uses
Sidef as a library, or plugins not included in the Sidef distribution) are
**not** covered by this policy.

### Supported Versions of Sidef

The maintainer will release security fixes for the **latest stable version**
of Sidef, distributed via CPAN. Older versions of Sidef are not actively
maintained for security fixes.

Users are strongly encouraged to upgrade to the latest release at all times.

Sidef is implemented in Perl and is regularly tested against recent Perl
releases. Note that the Sidef project only actively supports major versions of
Perl released in the **past ten (10) years**, even though Sidef may run on
older Perl versions. If a security fix requires the maintainer to increase the
minimum supported version of Perl, they may do so.

---

## Installation and Usage Issues

The distribution metadata specifies minimum versions of prerequisites required
for Sidef to work correctly. However, some prerequisites may themselves have
security vulnerabilities. You should ensure you are using up-to-date versions
of all prerequisites.

Where security vulnerabilities in prerequisites are known, the distribution
metadata may indicate newer recommended minimum versions.

Sidef is a general-purpose, high-level programming language that supports
dynamic code evaluation, file system access, network operations, and arbitrary
Perl module integration. When embedding Sidef in an application or using it
as a scripting engine, take care to:

- **Sandbox untrusted scripts** if Sidef is used to execute user-supplied code,
  as Sidef programs have the same access to system resources as the running
  process.
- **Validate external input** passed into Sidef programs, particularly any
  data used to construct file paths, shell commands, or network requests.
- **Restrict module imports** if running untrusted code, since Sidef's seamless
  Perl module integration means an untrusted script could load arbitrary CPAN
  modules.

Please see the [Sidef documentation](https://metacpan.org/pod/Sidef) for further guidance on safe usage patterns.

---

## Workflow

Upon receiving a security report, the maintainer will:

1. **Acknowledge** receipt of the report as soon as possible (target: within 7 days).
2. **Reproduce** and confirm the vulnerability.
3. **Develop** and test a fix in a private branch.
4. **Coordinate disclosure** with the reporter and, if appropriate, CPANSec.
5. **Release** a patched version to CPAN and publish a public advisory.
6. **Credit** the reporter (unless they request otherwise).

If the issue is complex or involves coordinating with other upstream projects,
a reasonable embargo period will be agreed with the reporter before public
disclosure.

---

*Copyright © 2013–2026 Daniel Șuteu. Sidef is distributed under the
[Artistic License 2.0](https://www.perlfoundation.org/artistic-license-20.html).*
