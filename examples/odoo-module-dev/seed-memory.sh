#!/bin/bash
# ===========================================
# Seed Global Memory with Odoo Development Knowledge
# ===========================================
# Usage: bash examples/odoo-module-dev/seed-memory.sh
#
# This seeds the team memory with Odoo conventions,
# patterns, and snippets so every agent starts informed.

MEMORY_URL="${MEMORIX_URL:-http://localhost:3100}"

save_memory() {
  local type=$1
  local id=$2
  local content=$3
  local author=${4:-"seed-script"}
  local tags=$5

  curl -s -X POST "$MEMORY_URL/mcp" \
    -H "Content-Type: application/json" \
    -d "{\"params\":{\"name\":\"memory_save\",\"arguments\":{\"type\":\"$type\",\"id\":\"$id\",\"content\":$(echo "$content" | jq -Rs .),\"metadata\":{\"author\":\"$author\",\"tags\":$tags}}}}" \
    | jq -r '.content[0].text // .error'
}

echo "============================================"
echo "  Seeding Odoo Development Knowledge"
echo "============================================"
echo ""

# ===========================================
# Facts - Odoo Conventions
# ===========================================
echo "[facts] Odoo conventions..."

save_memory "fact" "odoo-manifest" \
  "__manifest__.py required keys: name, version, category, summary, description, depends, data, installable, application, auto_install, license. Version format: ODOO_VERSION.MODULE_MAJOR.MODULE_MINOR (e.g., 17.0.1.0)" \
  "seed" '["odoo","manifest"]'

save_memory "fact" "odoo-model-naming" \
  "Model naming: use dot notation (e.g., estate.property, hr.overtime.request). Table name is auto-generated replacing dots with underscores. Module technical name uses underscores (e.g., estate_property). Always set _description on models." \
  "seed" '["odoo","model","naming"]'

save_memory "fact" "odoo-field-conventions" \
  "Field conventions: Many2one ends with _id (partner_id), One2many ends with _ids (line_ids), Many2many ends with _ids. Boolean starts with is_ or has_. Date fields end with _date. State fields use selection with standard states. Always add string= for translatable label." \
  "seed" '["odoo","fields"]'

save_memory "fact" "odoo-inheritance-types" \
  "Odoo inheritance: (1) _inherit=same _name: extend model in-place (add fields/methods). (2) _inherit=parent, _name=new: delegation/prototype inheritance, creates new model. (3) _inherits={parent: parent_id}: delegation, auto-delegate field access. Use type 1 for 90% of cases." \
  "seed" '["odoo","inheritance"]'

save_memory "fact" "odoo-view-priority" \
  "View inheritance priority: lower number = higher priority. Default is 16. Use priority < 16 to override, > 16 to extend. Use xpath expr to target elements. position: before, after, inside, replace, attributes." \
  "seed" '["odoo","views"]'

save_memory "fact" "odoo-security-model" \
  "Security layers: (1) ir.model.access.csv for CRUD per group, (2) ir.rule for record-level rules with domain filters, (3) groups for role-based access. Always define base group and manager group. CSV format: id,name,model_id:id,group_id:id,perm_read,perm_write,perm_create,perm_unlink" \
  "seed" '["odoo","security"]'

save_memory "fact" "odoo-workflow-pattern" \
  "State machine pattern: Use Selection field 'state' with default='draft'. Define action methods: action_confirm(), action_approve(), action_done(), action_cancel(), action_draft(). Use @api.constrains or write() override to enforce valid transitions. Add tracking=True for chatter logging." \
  "seed" '["odoo","workflow","state"]'

# ===========================================
# Snippets - Reusable Code Patterns
# ===========================================
echo "[snippets] Code patterns..."

save_memory "snippet" "odoo-model-template" \
'from odoo import models, fields, api, _
from odoo.exceptions import UserError, ValidationError


class ModelName(models.Model):
    _name = "module.model"
    _description = "Model Description"
    _inherit = ["mail.thread", "mail.activity.mixin"]
    _order = "create_date desc"

    name = fields.Char(string="Name", required=True, tracking=True)
    active = fields.Boolean(default=True)
    company_id = fields.Many2one(
        "res.company", string="Company",
        default=lambda self: self.env.company,
    )
    state = fields.Selection([
        ("draft", "Draft"),
        ("confirmed", "Confirmed"),
        ("done", "Done"),
        ("cancelled", "Cancelled"),
    ], string="Status", default="draft", tracking=True)

    def action_confirm(self):
        for rec in self:
            if rec.state != "draft":
                raise UserError(_("Only draft records can be confirmed."))
            rec.state = "confirmed"

    def action_done(self):
        self.filtered(lambda r: r.state == "confirmed").write({"state": "done"})

    def action_cancel(self):
        self.write({"state": "cancelled"})

    def action_draft(self):
        self.write({"state": "draft"})' \
  "seed" '["odoo","model","template"]'

save_memory "snippet" "odoo-form-view-template" \
'<record id="model_name_view_form" model="ir.ui.view">
    <field name="name">module.model.form</field>
    <field name="model">module.model</field>
    <field name="arch" type="xml">
        <form string="Model Name">
            <header>
                <button name="action_confirm" type="object"
                        string="Confirm" class="btn-primary"
                        invisible="state != '"'"'draft'"'"'"/>
                <button name="action_done" type="object"
                        string="Done"
                        invisible="state != '"'"'confirmed'"'"'"/>
                <button name="action_cancel" type="object"
                        string="Cancel"
                        invisible="state in ('"'"'done'"'"', '"'"'cancelled'"'"')"/>
                <field name="state" widget="statusbar"
                       statusbar_visible="draft,confirmed,done"/>
            </header>
            <sheet>
                <div class="oe_title">
                    <label for="name"/>
                    <h1><field name="name" placeholder="Name..."/></h1>
                </div>
                <group>
                    <group>
                        <!-- left column -->
                    </group>
                    <group>
                        <!-- right column -->
                    </group>
                </group>
                <notebook>
                    <page string="Details" name="details">
                        <!-- detail fields -->
                    </page>
                    <page string="Notes" name="notes">
                        <field name="note" placeholder="Add notes..."/>
                    </page>
                </notebook>
            </sheet>
            <chatter/>
        </form>
    </field>
</record>' \
  "seed" '["odoo","view","form","template"]'

save_memory "snippet" "odoo-tree-search-action" \
'<!-- Tree View -->
<record id="model_name_view_tree" model="ir.ui.view">
    <field name="name">module.model.tree</field>
    <field name="model">module.model</field>
    <field name="arch" type="xml">
        <tree string="Model Name" decoration-info="state == '"'"'draft'"'"'"
              decoration-success="state == '"'"'done'"'"'"
              decoration-muted="state == '"'"'cancelled'"'"'">
            <field name="name"/>
            <field name="state" widget="badge"
                   decoration-info="state == '"'"'draft'"'"'"
                   decoration-success="state == '"'"'done'"'"'"/>
        </tree>
    </field>
</record>

<!-- Search View -->
<record id="model_name_view_search" model="ir.ui.view">
    <field name="name">module.model.search</field>
    <field name="model">module.model</field>
    <field name="arch" type="xml">
        <search string="Search">
            <field name="name"/>
            <filter name="draft" string="Draft"
                    domain="[('"'"'state'"'"', '"'"'='"'"', '"'"'draft'"'"')]"/>
            <filter name="active" string="Active"
                    domain="[('"'"'state'"'"', '"'"'not in'"'"', ['"'"'done'"'"', '"'"'cancelled'"'"'])]"/>
            <separator/>
            <filter name="archived" string="Archived"
                    domain="[('"'"'active'"'"', '"'"'='"'"', False)]"/>
            <group expand="0" string="Group By">
                <filter name="group_state" string="Status"
                        context="{'"'"'group_by'"'"': '"'"'state'"'"'}"/>
            </group>
        </search>
    </field>
</record>

<!-- Action -->
<record id="model_name_action" model="ir.actions.act_window">
    <field name="name">Model Name</field>
    <field name="res_model">module.model</field>
    <field name="view_mode">tree,form,kanban</field>
    <field name="context">{"search_default_active": 1}</field>
    <field name="help" type="html">
        <p class="o_view_nocontent_smiling_face">
            Create your first record
        </p>
    </field>
</record>' \
  "seed" '["odoo","view","tree","search","action"]'

save_memory "snippet" "odoo-security-csv" \
'id,name,model_id:id,group_id:id,perm_read,perm_write,perm_create,perm_unlink
access_module_model_user,module.model.user,model_module_model,base.group_user,1,1,1,0
access_module_model_manager,module.model.manager,model_module_model,module_name.group_manager,1,1,1,1' \
  "seed" '["odoo","security","csv"]'

save_memory "snippet" "odoo-manifest-template" \
'{
    "name": "Module Title",
    "version": "17.0.1.0.0",
    "category": "Category",
    "summary": "Short description",
    "description": """Long description""",
    "author": "Team Name",
    "website": "https://example.com",
    "license": "LGPL-3",
    "depends": ["base", "mail"],
    "data": [
        "security/security.xml",
        "security/ir.model.access.csv",
        "views/model_name_views.xml",
        "views/menu.xml",
    ],
    "demo": [],
    "installable": True,
    "application": True,
    "auto_install": False,
}' \
  "seed" '["odoo","manifest","template"]'

save_memory "snippet" "odoo-test-template" \
'from odoo.tests.common import TransactionCase, tagged
from odoo.exceptions import UserError, ValidationError


@tagged("post_install", "-at_install")
class TestModelName(TransactionCase):

    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        cls.Model = cls.env["module.model"]
        cls.record = cls.Model.create({
            "name": "Test Record",
        })

    def test_create_record(self):
        self.assertEqual(self.record.state, "draft")
        self.assertTrue(self.record.active)

    def test_confirm_workflow(self):
        self.record.action_confirm()
        self.assertEqual(self.record.state, "confirmed")

    def test_cannot_confirm_twice(self):
        self.record.action_confirm()
        with self.assertRaises(UserError):
            self.record.action_confirm()

    def test_cancel_resets(self):
        self.record.action_confirm()
        self.record.action_cancel()
        self.assertEqual(self.record.state, "cancelled")' \
  "seed" '["odoo","test","template"]'

save_memory "snippet" "odoo-computed-field" \
'    total_amount = fields.Monetary(
        string="Total",
        compute="_compute_total_amount",
        store=True,
        currency_field="currency_id",
    )

    @api.depends("line_ids.subtotal")
    def _compute_total_amount(self):
        for rec in self:
            rec.total_amount = sum(rec.line_ids.mapped("subtotal"))' \
  "seed" '["odoo","computed","field"]'

save_memory "snippet" "odoo-record-rule" \
'<!-- security/security.xml -->
<odoo>
    <!-- Groups -->
    <record id="group_user" model="res.groups">
        <field name="name">User</field>
        <field name="category_id" ref="base.module_category_services"/>
        <field name="implied_ids" eval="[(4, ref('"'"'base.group_user'"'"'))]"/>
    </record>

    <record id="group_manager" model="res.groups">
        <field name="name">Manager</field>
        <field name="category_id" ref="base.module_category_services"/>
        <field name="implied_ids" eval="[(4, ref('"'"'group_user'"'"'))]"/>
    </record>

    <!-- Record Rules -->
    <record id="rule_own_records" model="ir.rule">
        <field name="name">Own Records Only</field>
        <field name="model_id" ref="model_module_model"/>
        <field name="domain_force">[("create_uid", "=", user.id)]</field>
        <field name="groups" eval="[(4, ref('"'"'group_user'"'"'))]"/>
        <field name="perm_read" eval="True"/>
        <field name="perm_write" eval="True"/>
        <field name="perm_create" eval="True"/>
        <field name="perm_unlink" eval="False"/>
    </record>

    <record id="rule_manager_all" model="ir.rule">
        <field name="name">Manager See All</field>
        <field name="model_id" ref="model_module_model"/>
        <field name="domain_force">[(1, "=", 1)]</field>
        <field name="groups" eval="[(4, ref('"'"'group_manager'"'"'))]"/>
    </record>
</odoo>' \
  "seed" '["odoo","security","record-rule","groups"]'

# ===========================================
# Feedback - Team Preferences
# ===========================================
echo "[feedback] Team preferences..."

save_memory "feedback" "odoo-no-core-modify" \
  "Never modify Odoo core modules directly. Always create a custom module that inherits and extends. Why: core modifications break on upgrade. How to apply: use _inherit to extend models, xpath to extend views." \
  "seed" '["odoo","rule"]'

save_memory "feedback" "odoo-use-mail-mixin" \
  "Always inherit mail.thread and mail.activity.mixin for business models. Why: enables chatter, tracking, activities out of the box. How to apply: add to _inherit list and add <chatter/> in form view." \
  "seed" '["odoo","mail","chatter"]'

save_memory "feedback" "odoo-test-first" \
  "Write tests for all business logic before marking task as done. Why: prevents regressions on Odoo upgrades. How to apply: create tests/ directory with TransactionCase tests, use @tagged for test categories." \
  "seed" '["odoo","testing"]'

echo ""
echo "============================================"
echo "  Done! Seeded $(curl -s $MEMORY_URL/health | jq '.memories | to_entries | map(.value) | add') memories"
echo "============================================"
echo ""
echo "  View all: curl $MEMORY_URL/memories"
echo "  Copy agent: cp examples/odoo-module-dev/odoo-agent.md .opencode/agents/"
echo ""
