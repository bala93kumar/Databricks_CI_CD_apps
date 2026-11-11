from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.enum.text import PP_ALIGN
from pptx.dml.color import RGBColor
from pptx.enum.shapes import MSO_SHAPE

prs = Presentation()
prs.slide_width = Inches(10)
prs.slide_height = Inches(7.5)

DARK_BLUE = RGBColor(31, 78, 124)
LIGHT_BLUE = RGBColor(0, 120, 215)
ACCENT_ORANGE = RGBColor(255, 107, 53)
ACCENT_GREEN = RGBColor(22, 160, 133)
WHITE = RGBColor(255, 255, 255)
DARK_GRAY = RGBColor(51, 51, 51)
LIGHT_GRAY = RGBColor(240, 240, 240)

def add_title_slide(title, subtitle):
    slide = prs.slides.add_slide(prs.slide_layouts[6])
    bg = slide.background
    fill = bg.fill
    fill.solid()
    fill.fore_color.rgb = DARK_BLUE

    top_bar = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(0), Inches(0), Inches(10), Inches(0.3))
    top_bar.fill.solid()
    top_bar.fill.fore_color.rgb = ACCENT_ORANGE
    top_bar.line.fill.background()

    title_box = slide.shapes.add_textbox(Inches(0.5), Inches(2.5), Inches(9), Inches(2))
    tf = title_box.text_frame
    tf.word_wrap = True
    p = tf.paragraphs[0]
    p.text = title
    p.font.size = Pt(54)
    p.font.bold = True
    p.font.color.rgb = WHITE
    p.alignment = PP_ALIGN.CENTER

    subtitle_box = slide.shapes.add_textbox(Inches(0.5), Inches(4.5), Inches(9), Inches(2))
    stf = subtitle_box.text_frame
    stf.word_wrap = True
    sp = stf.paragraphs[0]
    sp.text = subtitle
    sp.font.size = Pt(24)
    sp.font.color.rgb = ACCENT_ORANGE
    sp.alignment = PP_ALIGN.CENTER

def add_content_slide(title):
    slide = prs.slides.add_slide(prs.slide_layouts[6])
    bg = slide.background
    fill = bg.fill
    fill.solid()
    fill.fore_color.rgb = WHITE

    title_bar = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(0), Inches(0), Inches(10), Inches(1))
    title_bar.fill.solid()
    title_bar.fill.fore_color.rgb = DARK_BLUE
    title_bar.line.fill.background()

    line = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(0), Inches(0.95), Inches(10), Inches(0.08))
    line.fill.solid()
    line.fill.fore_color.rgb = ACCENT_ORANGE
    line.line.fill.background()

    title_box = slide.shapes.add_textbox(Inches(0.5), Inches(0.2), Inches(9), Inches(0.7))
    tf = title_box.text_frame
    p = tf.paragraphs[0]
    p.text = title
    p.font.size = Pt(40)
    p.font.bold = True
    p.font.color.rgb = WHITE

    return slide

# SLIDE 1: TITLE
add_title_slide("Azure Databricks Platform", "Enterprise Governance & FinOps as Code")

# SLIDE 2: AGENDA
slide2 = add_content_slide("Agenda")
agenda_box = slide2.shapes.add_textbox(Inches(1), Inches(1.5), Inches(8), Inches(5.5))
af = agenda_box.text_frame
af.word_wrap = True
items = ["1.  Two-Repo Architecture", "2.  Why Separation Matters?", "3.  Azure Infrastructure", "4.  Unity Catalog Medallion", "5.  RBAC & Security", "6.  GitOps Workflow", "7.  Live Demo"]
for idx, item in enumerate(items):
    if idx > 0:
        af.add_paragraph()
    p = af.paragraphs[idx]
    p.text = item
    p.font.size = Pt(22)
    p.font.color.rgb = DARK_GRAY
    p.space_before = Pt(10)

# SLIDE 3: TWO-REPO ARCHITECTURE
slide3 = add_content_slide("Two-Repo Architecture")
repo1 = slide3.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(0.5), Inches(1.5), Inches(4.2), Inches(5.5))
repo1.fill.solid()
repo1.fill.fore_color.rgb = RGBColor(230, 245, 255)
repo1.line.color.rgb = LIGHT_BLUE
repo1.line.width = Pt(2)

repo1_text = slide3.shapes.add_textbox(Inches(0.7), Inches(1.7), Inches(3.8), Inches(5.1))
rtf1 = repo1_text.text_frame
rtf1.word_wrap = True
rp1 = rtf1.paragraphs[0]
rp1.text = "REPO 1\nAdmin Repo"
rp1.font.size = Pt(16)
rp1.font.bold = True
rp1.font.color.rgb = LIGHT_BLUE
items1 = ["Cloud Infrastructure", "VNets & Storage", "Workspaces", "Unity Catalog", "Developer Onboarding", "RBAC Policies", "Terraform", "CI/CD Pipeline"]
for item in items1:
    rp = rtf1.add_paragraph()
    rp.text = "• " + item
    rp.font.size = Pt(12)
    rp.font.color.rgb = DARK_GRAY
    rp.space_before = Pt(5)

repo2 = slide3.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(5.3), Inches(1.5), Inches(4.2), Inches(5.5))
repo2.fill.solid()
repo2.fill.fore_color.rgb = RGBColor(255, 240, 230)
repo2.line.color.rgb = ACCENT_ORANGE
repo2.line.width = Pt(2)

repo2_text = slide3.shapes.add_textbox(Inches(5.5), Inches(1.7), Inches(3.8), Inches(5.1))
rtf2 = repo2_text.text_frame
rtf2.word_wrap = True
rp2 = rtf2.paragraphs[0]
rp2.text = "REPO 2\nDeveloper Repo"
rp2.font.size = Pt(16)
rp2.font.bold = True
rp2.font.color.rgb = ACCENT_ORANGE
items2 = ["PySpark Code", "Transformations", "Business Logic", "Unit Tests", "Data Quality", "DAB Bundles", "Job Definitions", "Local Testing"]
for item in items2:
    rp = rtf2.add_paragraph()
    rp.text = "• " + item
    rp.font.size = Pt(12)
    rp.font.color.rgb = DARK_GRAY
    rp.space_before = Pt(5)

# SLIDE 4: WHY SEPARATION
slide4 = add_content_slide("Why Separation Matters?")
benefits_box = slide4.shapes.add_textbox(Inches(0.8), Inches(1.5), Inches(8.4), Inches(5.5))
bf = benefits_box.text_frame
bf.word_wrap = True
benefits = ["🔒 Security: PROD protected with code review gates", "📊 Scalability: Teams work independently", "🎯 Single Responsibility: Infra ≠ Code", "🚀 Speed: Dev changes don't affect PROD", "📝 Compliance: All changes tracked in Git", "🧑‍💻 Experience: Write logic without infra concerns"]
for idx, benefit in enumerate(benefits):
    if idx > 0:
        bf.add_paragraph()
    p = bf.paragraphs[idx]
    p.text = benefit
    p.font.size = Pt(19)
    p.font.color.rgb = DARK_GRAY
    p.space_before = Pt(12)

# SLIDE 5: AZURE ARCHITECTURE
slide5 = add_content_slide("Azure Architecture")
dev_box = slide5.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(0.5), Inches(1.5), Inches(4.5), Inches(5.5))
dev_box.fill.solid()
dev_box.fill.fore_color.rgb = RGBColor(230, 250, 240)
dev_box.line.color.rgb = ACCENT_GREEN
dev_box.line.width = Pt(2)

dev_text = slide5.shapes.add_textbox(Inches(0.7), Inches(1.7), Inches(4.1), Inches(5.1))
dtf = dev_text.text_frame
dtf.word_wrap = True
dp = dtf.paragraphs[0]
dp.text = "DEV Environment"
dp.font.size = Pt(16)
dp.font.bold = True
dp.font.color.rgb = ACCENT_GREEN
dev_items = ["Workspace ID:", "adb-7405605201845024", "", "Storage:", "dbxdemodev80en", "", "Compute:", "dev-cluster-<user>", "10-min auto-terminate", "", "RBAC: Full Write"]
for item in dev_items:
    dp = dtf.add_paragraph()
    dp.text = item
    dp.font.size = Pt(11)
    dp.font.color.rgb = DARK_GRAY
    dp.space_before = Pt(3)

prod_box = slide5.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(5.3), Inches(1.5), Inches(4.2), Inches(5.5))
prod_box.fill.solid()
prod_box.fill.fore_color.rgb = RGBColor(255, 245, 230)
prod_box.line.color.rgb = ACCENT_ORANGE
prod_box.line.width = Pt(2)

prod_text = slide5.shapes.add_textbox(Inches(5.5), Inches(1.7), Inches(3.8), Inches(5.1))
ptf = prod_text.text_frame
ptf.word_wrap = True
pp = ptf.paragraphs[0]
pp.text = "PROD Environment"
pp.font.size = Pt(16)
pp.font.bold = True
pp.font.color.rgb = ACCENT_ORANGE
prod_items = ["Workspace ID:", "adb-7405618385351801", "", "Storage:", "dbxdemoprod80en", "", "Compute:", "DAB Job Clusters", "Zero idle cost", "", "RBAC: Read-Only"]
for item in prod_items:
    pp = ptf.add_paragraph()
    pp.text = item
    pp.font.size = Pt(11)
    pp.font.color.rgb = DARK_GRAY
    pp.space_before = Pt(3)

# SLIDE 6: MEDALLION SCHEMAS
slide6 = add_content_slide("Unity Catalog: Medallion Pattern")
schemas = [("Bronze", "Raw Data", "Ingested\nNo transforms"), ("Silver", "Cleaned", "Validated\nConformed"), ("Gold", "KPIs", "Analytics\nReady")]
x_pos = [0.5, 3.5, 6.5]
colors = [RGBColor(200, 150, 100), RGBColor(200, 200, 100), RGBColor(255, 215, 0)]
for idx, (level, subtitle, desc) in enumerate(schemas):
    box = slide6.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(x_pos[idx]), Inches(1.5), Inches(2.8), Inches(5.5))
    box.fill.solid()
    box.fill.fore_color.rgb = colors[idx]
    box.line.color.rgb = DARK_GRAY
    box.line.width = Pt(2)

    btext = slide6.shapes.add_textbox(Inches(x_pos[idx] + 0.15), Inches(1.7), Inches(2.5), Inches(5.1))
    btf = btext.text_frame
    btf.word_wrap = True
    bp = btf.paragraphs[0]
    bp.text = level
    bp.font.size = Pt(20)
    bp.font.bold = True
    bp.font.color.rgb = WHITE
    bp.alignment = PP_ALIGN.CENTER

    bp2 = btf.add_paragraph()
    bp2.text = subtitle
    bp2.font.size = Pt(13)
    bp2.font.color.rgb = WHITE
    bp2.alignment = PP_ALIGN.CENTER
    bp2.space_before = Pt(8)

    bp3 = btf.add_paragraph()
    bp3.text = desc
    bp3.font.size = Pt(11)
    bp3.font.color.rgb = RGBColor(50, 50, 50)
    bp3.space_before = Pt(16)

# SLIDE 7: GITOPS WORKFLOW
slide7 = add_content_slide("GitOps Workflow")
steps = [("1", "Push\nDEV", Inches(0.5)), ("2", "Terraform\nDEV", Inches(2)), ("3", "PR\nReview", Inches(3.5)), ("4", "Approve", Inches(5)), ("5", "Merge\nMAIN", Inches(6.5)), ("6", "Deploy\nPROD", Inches(8))]
for num, label, xp in steps:
    box = slide7.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, xp, Inches(2), Inches(1.2), Inches(1.3))
    box.fill.solid()
    box.fill.fore_color.rgb = LIGHT_BLUE if int(num) % 2 == 1 else ACCENT_ORANGE
    box.line.width = Pt(2)

    tbox = slide7.shapes.add_textbox(xp + Inches(0.1), Inches(2.1), Inches(1), Inches(1.1))
    tf = tbox.text_frame
    tf.word_wrap = True
    p = tf.paragraphs[0]
    p.text = label
    p.font.size = Pt(10)
    p.font.bold = True
    p.font.color.rgb = WHITE
    p.alignment = PP_ALIGN.CENTER

flow_text = slide7.shapes.add_textbox(Inches(0.8), Inches(3.8), Inches(8.4), Inches(3))
ftf = flow_text.text_frame
ftf.word_wrap = True
fp = ftf.paragraphs[0]
fp.text = "✓ DEV Isolated: dev branch changes apply ONLY to DEV workspace"
fp.font.size = Pt(14)
fp.font.bold = True
fp.font.color.rgb = LIGHT_BLUE
fp.space_before = Pt(10)

fp2 = ftf.add_paragraph()
fp2.text = "✓ PROD Protected: All PROD changes require PR review & merge to main"
fp2.font.size = Pt(14)
fp2.font.bold = True
fp2.font.color.rgb = ACCENT_ORANGE
fp2.space_before = Pt(12)

# SLIDE 8: FINOPS
slide8 = add_content_slide("FinOps: Zero Standby Cost")
finops_box = slide8.shapes.add_textbox(Inches(0.8), Inches(1.5), Inches(8.4), Inches(5.5))
fof = finops_box.text_frame
fof.word_wrap = True
finops_items = ["✅ NO NAT Gateway = Saves $32/month standby fee", "✅ Single-node clusters (0 workers) for development", "✅ 10-minute auto-termination on idle", "✅ Cluster creation blocked = prevents sprawl", "✅ Verified Cost: Less than ₹20 for days of dev/prod testing", "✅ Result: Predictable, minimal infrastructure costs"]
for idx, item in enumerate(finops_items):
    if idx > 0:
        fof.add_paragraph()
    p = fof.paragraphs[idx]
    p.text = item
    p.font.size = Pt(17)
    p.font.color.rgb = DARK_GRAY
    p.space_before = Pt(14)

# SLIDE 9: KEY TAKEAWAYS
slide9 = add_content_slide("Key Takeaways")
takeaway_box = slide9.shapes.add_textbox(Inches(0.8), Inches(1.5), Inches(8.4), Inches(5.5))
tf = takeaway_box.text_frame
tf.word_wrap = True
takeaways = ["✅ Infrastructure & Application fully decoupled", "✅ Zero-cost networking + auto-terminating compute", "✅ 100% declarative governance (no manual UI)", "✅ Dev freedom meets PROD protection", "✅ GitOps: Safe, auditable, reviewable changes"]
for idx, item in enumerate(takeaways):
    if idx > 0:
        tf.add_paragraph()
    p = tf.paragraphs[idx]
    p.text = item
    p.font.size = Pt(18)
    p.font.color.rgb = DARK_GRAY
    p.space_before = Pt(16)

# SLIDE 10: RBAC SECURITY MODEL
slide10 = add_content_slide("RBAC: Security Model")
rbac_left = slide10.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(0.5), Inches(1.5), Inches(4.5), Inches(5.5))
rbac_left.fill.solid()
rbac_left.fill.fore_color.rgb = RGBColor(230, 245, 255)
rbac_left.line.color.rgb = LIGHT_BLUE
rbac_left.line.width = Pt(2)

rbac_l_text = slide10.shapes.add_textbox(Inches(0.7), Inches(1.7), Inches(4.1), Inches(5.1))
rltf = rbac_l_text.text_frame
rltf.word_wrap = True
rlp = rltf.paragraphs[0]
rlp.text = "DEV Workspace"
rlp.font.size = Pt(16)
rlp.font.bold = True
rlp.font.color.rgb = LIGHT_BLUE
rbac_l_items = ["Data Engineers:", "USE_SCHEMA", "SELECT", "MODIFY", "CREATE_TABLE", "", "Full Write Access", "for testing"]
for item in rbac_l_items:
    rlp = rltf.add_paragraph()
    rlp.text = item
    rlp.font.size = Pt(12)
    rlp.font.color.rgb = DARK_GRAY
    rlp.space_before = Pt(5)

rbac_right = slide10.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(5.3), Inches(1.5), Inches(4.2), Inches(5.5))
rbac_right.fill.solid()
rbac_right.fill.fore_color.rgb = RGBColor(255, 240, 230)
rbac_right.line.color.rgb = ACCENT_ORANGE
rbac_right.line.width = Pt(2)

rbac_r_text = slide10.shapes.add_textbox(Inches(5.5), Inches(1.7), Inches(3.8), Inches(5.1))
rrtf = rbac_r_text.text_frame
rrtf.word_wrap = True
rrp = rrtf.paragraphs[0]
rrp.text = "PROD Workspace"
rrp.font.size = Pt(16)
rrp.font.bold = True
rrp.font.color.rgb = ACCENT_ORANGE
rbac_r_items = ["Data Engineers:", "USE_SCHEMA", "SELECT (Read-Only)", "", "Service Principal:", "Full Ownership", "for DAB pipelines"]
for item in rbac_r_items:
    rrp = rrtf.add_paragraph()
    rrp.text = item
    rrp.font.size = Pt(12)
    rrp.font.color.rgb = DARK_GRAY
    rrp.space_before = Pt(5)

# SLIDE 11: DEVELOPER ONBOARDING
slide11 = add_content_slide("Developer Lifecycle (100% Declarative)")
onboard_box = slide11.shapes.add_textbox(Inches(0.8), Inches(1.5), Inches(8.4), Inches(5.5))
obf = onboard_box.text_frame
obf.word_wrap = True
onboard_items = [
    "ONBOARDING: Add email to locals.data_engineers in code",
    "  -> Auto-creates user account",
    "  -> Auto-assigns personal cluster (dev-cluster-<username>)",
    "  -> Auto-grants DEV workspace access",
    "",
    "OFFBOARDING: Remove/comment developer from code",
    "  -> Auto-revokes all grants",
    "  -> Auto-deletes cluster",
    "  -> Auto-purges home directory",
    "",
    "Zero manual work. 100% declarative. Fully auditable."
]
for idx, item in enumerate(onboard_items):
    if idx > 0:
        obf.add_paragraph()
    p = obf.paragraphs[idx]
    p.text = item
    p.font.size = Pt(15)
    p.font.color.rgb = DARK_GRAY
    p.space_before = Pt(6)

# SLIDE 12: CI/CD PIPELINE
slide12 = add_content_slide("CI/CD: GitHub Actions Pipeline")
cicd_box = slide12.shapes.add_textbox(Inches(0.8), Inches(1.5), Inches(8.4), Inches(5.5))
ccf = cicd_box.text_frame
ccf.word_wrap = True
cicd_items = [
    "EVERY COMMIT: Automated Terraform plan",
    "  -> Validates infrastructure changes",
    "  -> Posts plan preview in PR",
    "",
    "DEV BRANCH: Applies ONLY to DEV workspace",
    "  -> Fast feedback for developers",
    "  -> No risk to production",
    "",
    "MAIN BRANCH: Applies to PROD workspace",
    "  -> Requires PR review & approval",
    "  -> Automatic deployment on merge"
]
for idx, item in enumerate(cicd_items):
    if idx > 0:
        ccf.add_paragraph()
    p = ccf.paragraphs[idx]
    p.text = item
    p.font.size = Pt(15)
    p.font.color.rgb = DARK_GRAY
    p.space_before = Pt(6)

# SLIDE 13: LIVE DEMO CHECKLIST
slide13 = add_content_slide("Live Demo Checklist")
demo_box = slide13.shapes.add_textbox(Inches(0.8), Inches(1.5), Inches(8.4), Inches(5.5))
dmf = demo_box.text_frame
dmf.word_wrap = True
demo_items = [
    "1. Show DEV workspace with live catalogs",
    "   - Catalog: dbx_demo_dev_ws_7405605201845024",
    "   - Show marketing_bronze, marketing_silver, marketing_gold",
    "",
    "2. Show PROD workspace (separate catalogs)",
    "   - Catalog: dbx_demo_prod_ws_7405618385351801",
    "",
    "3. Show ADLS Gen2 storage with actual data",
    "   - DEV: dbxdemodev80en",
    "   - PROD: dbxdemoprod80en",
    "",
    "4. Show cost tracking & FinOps validation"
]
for idx, item in enumerate(demo_items):
    if idx > 0:
        dmf.add_paragraph()
    p = dmf.paragraphs[idx]
    p.text = item
    p.font.size = Pt(14)
    if item.startswith(("1", "2", "3", "4")):
        p.font.bold = True
        p.font.color.rgb = LIGHT_BLUE
    else:
        p.font.color.rgb = DARK_GRAY
    p.space_before = Pt(6)

# SLIDE 14: COST COMPARISON
slide14 = add_content_slide("Cost Efficiency: Before vs After")
cost_box = slide14.shapes.add_textbox(Inches(0.5), Inches(1.5), Inches(9), Inches(5.5))
ctf = cost_box.text_frame
ctf.word_wrap = True

cp = ctf.paragraphs[0]
cp.text = "BEFORE (Traditional Setup):"
cp.font.size = Pt(16)
cp.font.bold = True
cp.font.color.rgb = RGBColor(200, 50, 50)

before_items = [
    "NAT Gateway: $32/month (standby fee)",
    "Always-on VMs: $200+/month",
    "Manual cluster management: Wasteful",
    "No auto-termination: Constant idle costs"
]
for item in before_items:
    p = ctf.add_paragraph()
    p.text = "  • " + item
    p.font.size = Pt(13)
    p.font.color.rgb = DARK_GRAY

cp2 = ctf.add_paragraph()
cp2.text = "AFTER (Our FinOps Architecture):"
cp2.font.size = Pt(16)
cp2.font.bold = True
cp2.font.color.rgb = ACCENT_GREEN
cp2.space_before = Pt(16)

after_items = [
    "Zero-NAT Gateway: $0/month (saves $32)",
    "Auto-terminating compute: Minimal cost",
    "Automated cluster management: Efficient",
    "Verified real-world: <20 INR/month"
]
for item in after_items:
    p = ctf.add_paragraph()
    p.text = "  • " + item
    p.font.size = Pt(13)
    p.font.color.rgb = DARK_GRAY

# SLIDE 15: ARCHITECTURE SUMMARY
slide15 = add_content_slide("Architecture Summary")
summary_box = slide15.shapes.add_textbox(Inches(0.8), Inches(1.5), Inches(8.4), Inches(5.5))
smf = summary_box.text_frame
smf.word_wrap = True

summary_items = [
    "Azure Resource Group: dbx-demo-cicd-rg",
    "VNet: Zero-NAT (Custom subnets with public IP egress)",
    "Storage: ADLS Gen2 for DEV and PROD",
    "Workspaces: Separate DEV (7405605201845024) & PROD (7405618385351801)",
    "Catalogs: Native workspace catalogs (dbx_demo_dev_ws / dbx_demo_prod_ws)",
    "Terraform: IaC for complete automation",
    "GitHub Actions: CI/CD for branch-targeted deployments"
]

for idx, item in enumerate(summary_items):
    if idx > 0:
        smf.add_paragraph()
    p = smf.paragraphs[idx]
    p.text = item
    p.font.size = Pt(15)
    p.font.color.rgb = DARK_GRAY
    p.space_before = Pt(10)

# SLIDE 16: Q&A
slide16 = prs.slides.add_slide(prs.slide_layouts[6])
bgq = slide16.background
fillq = bgq.fill
fillq.solid()
fillq.fore_color.rgb = DARK_BLUE

top_bar_q = slide16.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(0), Inches(0), Inches(10), Inches(0.3))
top_bar_q.fill.solid()
top_bar_q.fill.fore_color.rgb = ACCENT_ORANGE
top_bar_q.line.fill.background()

qa_box = slide16.shapes.add_textbox(Inches(1), Inches(2.5), Inches(8), Inches(2))
qaf = qa_box.text_frame
qaf.word_wrap = True
qap = qaf.paragraphs[0]
qap.text = "Questions & Discussion"
qap.font.size = Pt(54)
qap.font.bold = True
qap.font.color.rgb = WHITE
qap.alignment = PP_ALIGN.CENTER

qa_sub = slide16.shapes.add_textbox(Inches(1), Inches(4.8), Inches(8), Inches(1))
qsf = qa_sub.text_frame
qsp = qsf.paragraphs[0]
qsp.text = "Ready for Live Demo!"
qsp.font.size = Pt(32)
qsp.font.color.rgb = ACCENT_ORANGE
qsp.alignment = PP_ALIGN.CENTER

prs.save("Databricks_Platform_CI_CD_Demo.pptx")
print("SUCCESS! Enhanced presentation created!")
print("SLIDES: 16 with comprehensive content and visuals")
print("FILE: Databricks_Platform_CI_CD_Demo.pptx")
