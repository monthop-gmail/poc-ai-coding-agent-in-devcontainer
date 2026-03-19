# Example: Using AI Coding Agent for Odoo Module Development

This example shows how to use OpenCode + Global Memory to develop Odoo modules efficiently as a team.

## Setup

### 1. Seed team memory with Odoo conventions

```bash
# Run the seed script to load Odoo knowledge into global memory
bash examples/odoo-module-dev/seed-memory.sh
```

### 2. Use the Odoo agent

In OpenCode, switch to the Odoo agent:

```
@odoo create a new module called "estate_property" for managing real estate listings
```

### 3. Example prompts

```
# Scaffold a new module
@odoo scaffold a module "hr_overtime" for tracking employee overtime with approval workflow

# Add a model
@odoo add a model "overtime.request" with fields: employee_id, date_from, date_to, hours, state (draft/confirmed/approved/refused)

# Create views
@odoo create tree, form, and search views for overtime.request with kanban by state

# Add business logic
@odoo add approval workflow: draft -> confirmed -> approved, with email notification on approval

# Security
@odoo create security rules: employees see own records, managers see department, hr sees all

# Inherit existing model
@odoo extend hr.employee to add a field "overtime_balance" computed from approved requests

# Reports
@odoo create a QWeb PDF report for monthly overtime summary grouped by department
```

## What the agent remembers

After seeding, the agent knows:
- Odoo module structure and conventions
- ORM patterns (fields, compute, constraints, onchange)
- View XML patterns (form, tree, kanban, search)
- Security model (ir.model.access.csv, record rules)
- Common inheritance patterns
- Testing patterns
- Your team's specific conventions (saved as feedback)

## Files

| File | Purpose |
|------|---------|
| `seed-memory.sh` | Seeds global memory with Odoo development knowledge |
| `odoo-agent.md` | Custom OpenCode agent for Odoo development |
| `scaffold-template/` | Example module template the agent follows |
