trigger OpportunityTriggers on Opportunity (before insert, after insert, before update, after update) {

    if (Trigger.isAfter && Trigger.isInsert) { 
     
        List<Approval.ProcessSubmitRequest> ap_list = new List<Approval.ProcessSubmitRequest>(); 
              
        for (Opportunity opp : Trigger.New) {  
   
            if (opp.Source__c <> null && opp.Source__c == 'Case') {   
                // create the new approval request to submit
                Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                req.setComments('För godkännande. Var snäll och godkänn.');
                req.setObjectId(opp.Id);
                // submit the approval request for processing
                if(req <> null) {
                    ap_list.add(req);
                } 
            }
        }
        
        if(ap_list.size() > 0) {
            Approval.ProcessResult[] processResults = null;
            try {
                processResults = Approval.process(ap_list, true);
            }
            catch (System.DmlException e) {
                System.debug('Exception Is ' + e.getMessage());
            }
        }
    }
    
}