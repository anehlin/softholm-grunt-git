trigger CaseProductTriggers on CaseProductObject__c (before insert, before update, after insert, after update) {

    //Create a set for Case ids
    Set<ID> caseIds = new Set<ID>();

    for(CaseProductObject__c cpo : Trigger.New) {
        caseIds.add(cpo.Case__c);
    }
    
    if(Trigger.isUpdate) {
        
        List<Case> casesToUpdate = [Select id From Case
                                    Where id in: caseIds];
    
        if(casesToUpdate.size() > 0) update casesToUpdate;
    }

}