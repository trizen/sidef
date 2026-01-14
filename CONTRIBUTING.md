# Contributing to Sidef

Thank you for your interest in contributing to Sidef! We appreciate your support in making this modern programming language better for everyone.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How Can I Contribute?](#how-can-i-contribute)
  - [Reporting Bugs](#reporting-bugs)
  - [Suggesting Enhancements](#suggesting-enhancements)
  - [Code Contributions](#code-contributions)
  - [Documentation](#documentation)
  - [Examples and Scripts](#examples-and-scripts)
- [Development Setup](#development-setup)
- [Style Guidelines](#style-guidelines)
- [Testing](#testing)
- [Pull Request Process](#pull-request-process)
- [Community](#community)

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment. We expect all contributors to:

- Use welcoming and inclusive language
- Be respectful of differing viewpoints and experiences
- Accept constructive criticism gracefully
- Focus on what's best for the community
- Show empathy towards other community members

## Getting Started

1. **Familiarize yourself with Sidef:**
   - Read the [Tutorial](https://codeberg.org/trizen/sidef/src/branch/master/TUTORIAL.md)
   - Browse the [Documentation](https://trizen.gitbook.io/sidef-lang/)
   - Try examples at [Try It Online](https://tio.run/#sidef)
   - Explore [RosettaCode examples](https://rosettacode.org/wiki/Sidef)

2. **Set up your environment:**
   - Fork the repository on GitHub
   - Clone your fork locally
   - Install dependencies (see [Development Setup](#development-setup))

3. **Find something to work on:**
   - Check the [Issues](https://github.com/trizen/sidef/issues) page
   - Look for issues labeled `good first issue` or `help wanted`
   - Review the [TODO](https://github.com/trizen/sidef/blob/master/TODO) file

## How Can I Contribute?

### Reporting Bugs

Before creating a bug report, please check existing issues to avoid duplicates. When filing a bug report, include:

**Required Information:**
- **Clear title**: Brief, descriptive summary
- **Sidef version**: Output of `sidef --version`
- **Operating system**: Your OS and version
- **Perl version**: Output of `perl --version`
- **Description**: Clear explanation of the problem
- **Steps to reproduce**: Minimal code example demonstrating the issue
- **Expected behavior**: What you expected to happen
- **Actual behavior**: What actually happened
- **Error messages**: Complete error output, if any

**Example:**
```markdown
## Bug: Division by zero not properly caught

**Version:** Sidef 25.12
**OS:** Ubuntu 22.04
**Perl:** 5.34.0

**Code:**
```sidef
say (10 / 0)
```

**Expected:** Error message about division by zero

**Actual:** `[paste actual output]`

### Suggesting Enhancements

We welcome suggestions for new features! Please include:

- **Clear use case**: Why is this enhancement valuable?
- **Detailed description**: What should the feature do?
- **Examples**: Show how it would work with code samples
- **Alternatives considered**: Other approaches you've thought about
- **Implementation ideas**: If you have technical suggestions

### Code Contributions

We accept contributions in several areas:

**Core Language Features:**
- Parser improvements
- New built-in methods
- Performance optimizations
- Bug fixes

**Standard Library:**
- New modules
- Enhancements to existing modules
- Better Perl module integration

**Tools and Utilities:**
- REPL improvements
- Development tools
- Build system enhancements

### Documentation

Documentation contributions are highly valued:

- Fix typos and grammatical errors
- Clarify confusing explanations
- Add missing documentation
- Improve code examples
- Translate documentation
- Create tutorials or guides

### Examples and Scripts

Share your Sidef code:

- Add examples to [sidef-scripts](https://github.com/trizen/sidef-scripts)
- Contribute to [RosettaCode](https://rosettacode.org/wiki/Sidef)
- Write tutorials or blog posts
- Create educational materials

## Development Setup

### Prerequisites

- Perl 5.16.0 or higher
- Git
- Basic familiarity with Perl (for core development)

### Installation for Development

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/sidef.git
cd sidef

# Add upstream remote
git remote add upstream https://github.com/trizen/sidef.git

# Install dependencies
perl Build.PL
./Build installdeps

# Build
./Build

# Run tests
./Build test

# Install locally (optional)
./Build install
```

### Running Sidef from Source

```bash
# Run directly from the bin directory
./bin/sidef your_script.sf

# Or add to your PATH
export PATH="$PWD/bin:$PATH"
sidef your_script.sf
```

## Style Guidelines

### Sidef Code Style

When writing Sidef code examples:

- Use 4 spaces for indentation
- Follow the style in existing examples
- Use meaningful variable names
- Add comments for complex logic
- Keep lines under 100 characters when reasonable

```sidef
# Good
func fibonacci(n) {
    n < 2 ? n : (__FUNC__(n-1) + __FUNC__(n-2))
}

# Also good with clear formatting
func factorial(n) {
    n == 0 ? 1
           : (n * __FUNC__(n - 1))
}
```

### Perl Code Style (for core development)

- Follow Perl Best Practices
- Use meaningful variable names
- Add POD documentation for new modules
- Keep functions focused and small
- Use strict and warnings

### Commit Messages

Write clear, descriptive commit messages:

```
Brief summary (50 chars or less)

More detailed explanation if needed. Wrap at 72 characters.
Explain what changed and why, not just what was done.

- Bullet points are okay
- Use present tense: "Add feature" not "Added feature"
- Reference issues: "Fixes #123" or "Relates to #456"
```

**Examples:**
- `Fix regex parsing for nested quantifiers`
- `Add Number.harmonic_mean method`
- `Improve error messages for undefined variables`
- `Update documentation for Array methods`

## Testing

### Running Tests

```bash
# Run all tests
./Build test

# Run specific test file
prove -v t/specific_test.t

# Run tests verbosely
./Build test verbose=1
```

### Writing Tests

When adding new features:

1. Add tests in the `t/` directory
2. Follow existing test file patterns
3. Test both success and failure cases
4. Include edge cases
5. Ensure tests are reproducible

Example test structure:

```perl
#!/usr/bin/perl

use 5.016;
use strict;
use warnings;

use Test::More tests => 3;

# Your tests here
is($result, $expected, "Test description");
```

### Test Coverage

- Aim for comprehensive coverage of new code
- Don't break existing tests
- Update tests when changing functionality

## Pull Request Process

### Before Submitting

1. **Create a feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes:**
   - Follow the style guidelines
   - Add tests for new features
   - Update documentation as needed

3. **Test thoroughly:**
   ```bash
   ./Build test
   ```

4. **Commit with clear messages:**
   ```bash
   git commit -m "Add feature: description"
   ```

5. **Update your branch:**
   ```bash
   git fetch upstream
   git rebase upstream/master
   ```

### Submitting the Pull Request

1. **Push to your fork:**
   ```bash
   git push origin feature/your-feature-name
   ```

2. **Create the PR:**
   - Go to the repository on GitHub
   - Click "New Pull Request"
   - Select your branch
   - Fill out the PR template

3. **PR Description should include:**
   - What changes were made
   - Why these changes are needed
   - How to test the changes
   - References to related issues
   - Screenshots (if UI changes)

### PR Template Example

```markdown
## Description
Brief description of changes

## Motivation
Why is this change needed?

## Changes Made
- Change 1
- Change 2
- Change 3

## Testing
How to test these changes

## Related Issues
Fixes #123
Relates to #456

## Checklist
- [ ] Tests pass locally
- [ ] Documentation updated
- [ ] CHANGES file updated (if applicable)
- [ ] Code follows style guidelines
```

### Review Process

- Maintainers will review your PR
- Address feedback and questions
- Make requested changes if needed
- Be patient and respectful

### After Merging

- Delete your feature branch
- Pull the latest changes from upstream
- Thank the reviewers!

## Community

### Getting Help

- **Questions?** Use [GitHub Discussions](https://github.com/trizen/sidef/discussions/categories/q-a)
- **Chat:** Join conversations in discussions
- **Bugs:** Open an [issue](https://github.com/trizen/sidef/issues)

### Staying Updated

- Watch the repository for updates
- Follow discussions on GitHub
- Check the [CHANGES](https://github.com/trizen/sidef/blob/master/Changes) file for updates

### Recognition

Contributors are recognized in:
- The repository's contributors page
- Release notes for significant contributions
- The community through discussions and interactions

## Resources

- **Documentation:** [Sidef GitBook](https://trizen.gitbook.io/sidef-lang/)
- **Tutorial:** [Beginner's Tutorial](https://codeberg.org/trizen/sidef/src/branch/master/TUTORIAL.md)
- **Examples:** [sidef-scripts repository](https://github.com/trizen/sidef-scripts)
- **Try Online:** [TIO Platform](https://tio.run/#sidef)
- **RosettaCode:** [Sidef examples](https://rosettacode.org/wiki/Sidef)

## Questions?

If you have questions about contributing, feel free to:
- Open a discussion in the [Q&A category](https://github.com/trizen/sidef/discussions/categories/q-a)
- Comment on an existing issue
- Check existing documentation

Thank you for contributing to Sidef! Your efforts help make Sidef better for everyone.

---

**License:** By contributing to Sidef, you agree that your contributions will be licensed under the Artistic License 2.0.
