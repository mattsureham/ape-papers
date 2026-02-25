#!/bin/bash
# APE Pipeline - Multi-Field Support

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

case "${1:-menu}" in
    generate)
        # Basic: ./ape.sh generate "Question" [field] [method]
        python3 scripts/generate_paper.py "$2" "${3:-economics}" "${4:-}"
        ;;
    
    generate-field)
        # With field: ./ape.sh generate-field "Question" field method
        echo "📝 Generate Paper - Field: ${3:-economics}"
        python3 scripts/generate_paper.py "$2" "${3:-economics}" "${4:-}"
        ;;
    
    generate-dir)
        # With directories: ./ape.sh generate-dir "Question" field method data_dir refs_dir
        echo "📝 Generate Paper with Directories"
        echo "   Field: ${3:-economics}"
        echo "   Question: $2"
        python3 scripts/generate_paper.py "$2" "${3:-economics}" "${4:-}" "$5" "$6"
        ;;
    
    review)
        python3 scripts/review_paper.py "$2"
        ;;
    
    tournament)
        python3 scripts/tournament.py match "$2" "$3"
        ;;
    
    leaderboard)
        python3 scripts/tournament.py leaderboard
        ;;
    
    setup)
        ${EDITOR:-nano} config/.env
        ;;
    
    fields)
        echo "Supported Academic Fields"
        echo "========================="
        echo ""
        echo "1. economics (default)"
        echo "   - Journals: AER, QJE"
        echo "   - Methods: DiD, RDD, IV, RCT"
        echo ""
        echo "2. psychology"
        echo "   - Journals: JPSP, Psychological Science"
        echo "   - Methods: Experiment, Survey, Meta-analysis"
        echo ""
        echo "3. computer_science"
        echo "   - Journals: ACM, IEEE"
        echo "   - Methods: Algorithm, Benchmark, A/B test"
        echo ""
        echo "4. medicine"
        echo "   - Journals: NEJM, Lancet"
        echo "   - Methods: RCT, Cohort, Case-control"
        echo ""
        echo "5. sociology"
        echo "   - Journals: AJS, ASR"
        echo "   - Methods: Ethnography, Survey, Interview"
        echo ""
        echo "6. political_science"
        echo "   - Journals: APSR, AJPS"
        echo "   - Methods: Quantitative, Case study, Text analysis"
        echo ""
        echo "7. education"
        echo "   - Journals: AERA, RER"
        echo "   - Methods: Quasi-experiment, Mixed methods"
        echo ""
        echo "8. environmental_science"
        echo "   - Journals: Nature Climate Change, Science"
        echo "   - Methods: Modeling, Field measurements"
        ;;
    
    help)
        echo "APE Pipeline - Multi-Field Paper Generator"
        echo "=========================================="
        echo ""
        echo "Commands:"
        echo ""
        echo "1. Basic generation (economics default):"
        echo '   ./ape.sh generate "Question" [field] [method]'
        echo ""
        echo "2. Specific field:"
        echo '   ./ape.sh generate-field "Question" psychology "Survey"'
        echo ""
        echo "3. With directories:"
        echo '   ./ape.sh generate-dir "Question" field method data/ refs/'
        echo ""
        echo "Examples:"
        echo '   # Psychology paper'
        echo '   ./ape.sh generate-field "Social media and anxiety" psychology "Experiment"'
        echo ""
        echo '   # CS paper with data'
        echo '   ./ape.sh generate-dir "New algorithm" computer_science "Benchmark" data/ refs/'
        echo ""
        echo '   # Medicine RCT'
        echo '   ./ape.sh generate-field "Drug trial" medicine "RCT"'
        echo ""
        echo "See all fields: ./ape.sh fields"
        ;;
    
    *)
        echo "APE Pipeline - Multi-Field Academic Paper Generator"
        echo "==================================================="
        echo ""
        echo "Commands:"
        echo "  generate       - Generate paper (economics default)"
        echo "  generate-field - Generate for specific field"
        echo "  generate-dir   - Generate with data/refs directories"
        echo "  review         - Review paper"
        echo "  tournament     - Compare papers"
        echo "  leaderboard    - View rankings"
        echo "  fields         - List supported fields"
        echo "  setup          - Edit config"
        echo "  help           - Show help"
        echo ""
        echo "Quick start:"
        echo '  ./ape.sh generate-field "Your question" economics DiD'
        ;;
esac
