public class CaseController {

    private final Case c;

    public CaseController() {
        c = [SELECT Id FROM Case
                   WHERE Id = :ApexPages.currentPage().getParameters().get('id')];
    }

    //Testing to add a comment
    public Case getCase() {
        return c;
    }

    public PageReference save() {
        update c;
        return null;
    }
}