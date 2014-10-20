/******************************************************************************
*
* Author: Anders Nehlin
*
* Description:
* This trigger create an opportunity, with related opportunity line items.
*
* Change log:
* 2014-02-18 AndNeh Initial development.
* 2014-02-28 AndNeh Adding check for active users for the record ownership.
* 2014-05-08 AndNeh New functionality for coupling type of case to products.
* 2014-10-09 AndNeh Refactored the logic to create new opportunity and oppotunity
*                   line item from the CaseProductObject__c.
*
********************************************************************************/
trigger CaseTrigger2 on Case (before insert, before update, after insert, after update) {

    //Create a list of all cases
    List<Case> cases = new List<Case>();

    //Create a list of all cases
    List<Case> casesWithOpps = new List<Case>();

    //Create a set that hold all account ids
    Set<ID> accIds = new Set<ID>();

    //Create a set that hold all case ids that is closed
    Set<ID> closeCaseIds = new Set<ID>();

    //Create a set that hold all case ids that is closed
    Set<ID> caseWithOppsIds = new Set<ID>();
    
    for(Case c : Trigger.New) {
        if(Trigger.isInsert && Trigger.isBefore) {
           //Set the subject as the same as Typ_av_case__c
           c.Subject = (c.Typ_av_case__c != null || c.Typ_av_case__c != '') ? c.Typ_av_case__c : c.Subject;
        }

        accIds.add(c.AccountID);
        if(c.Status == 'Stängt') {
            cases.add(c);
            closeCaseIds.add(c.id);
        }

        if(c.hasOpportunity__c) {
            caseWithOppsIds.add(c.Id);
            casesWithOpps.add(c);
        }

    }


    //Get all CaseProductObject__c if any
    List<CaseProductObject__c> cpo_list = new List<CaseProductObject__c>();
    if(closeCaseIds.size() > 0) {
        cpo_list = [Select id, Product__c, Case__c, Enhetspris__c, Antal__c, PriceBookEntry__c
                         From CaseProductObject__c
                         Where Case__c in: closeCaseIds];
    }

    // Get all the selected accounts
    List<Account> accounts = [Select id, OwnerId From Account
                              Where id in: accIds];

    // Create a map with all active users
    Map<ID,User> active_users_map = new Map<ID,User>(
                                        [Select id From User
                                         Where isActive = true]);

    List<Profile> syst_admin_prof = [Select id From Profile
                                     Where Name = 'System Administrator'
                                     OR Name = 'Systemadministratör'
                                     Limit 1];

    // Get a default user
    List<User> default_user = [Select id, Name From User
                               Where isActive = true
                               And ProfileId =: syst_admin_prof.get(0).Id
                               And Name NOT IN ('Camilla Danielsson', 'api')
                               Order By Name asc
                               Limit 1];

    // Create a map to hold account id as key and account ownerid as value
    Map<ID,ID> accId_Owner_map = new Map<ID,ID>();

    for(Account a : accounts) {
        if(active_users_map.containskey(a.OwnerID)){
            accId_Owner_map.put(a.Id, a.OwnerID);
        }
        else {
            accId_Owner_map.put(a.Id, default_user.get(0).id);
        }
    }

    //Update opportunities if Case has been updated
    if(caseWithOppsIds.size() > 0 && Trigger.isAfter) {

        //Get all related opportunities
        List<Opportunity> opps = [Select id, Type, Name, Rabatt_kommentar__c, Best_llt_av__c,
                                  Information_om_s_ljprojekt__c, Case__c
                                  From Opportunity
                                  Where Case__c in: caseWithOppsIds];

        System.debug('has opps' + opps);

        Map<ID,Opportunity> opp_map = new Map<ID,Opportunity>(opps);

        //Create a map with Case id and Opportunity
        Map<ID,Opportunity> caseId_opp_map = new Map<ID,Opportunity>();
        for(Opportunity o : opps) {
            caseId_opp_map.put(o.Case__c, o);
        }
        
        //Get all related CaseProductObjects
        List<CaseProductObject__c> cpo_list_1 = [Select id, Product__c, Case__c, Enhetspris__c,
                                                 Antal__c, PriceBookEntry__c
                                                 From CaseProductObject__c
                                                 Where Case__c in: caseWithOppsIds];
        System.debug('caseWithOppsIds = ' + caseWithOppsIds);
        System.debug('cpo_list_1 = ' + cpo_list_1);
                                                 
        Map<ID,CaseProductObject__c> cpo_map = new Map<ID,CaseProductObject__c>(cpo_list);

        //Get all related opportunity line items
        List<OpportunityLineItem> oli_list = [Select id,PricebookEntryId,Quantity,UnitPrice, CaseProductObject__c
                                              From OpportunityLineItem
                                              Where OpportunityID in: opp_map.keyset()
                                              And CaseProductObject__c in: cpo_map.keyset()];

        //Create a map with PricebookEntryId and OpportunityLineItem
        Map<ID,OpportunityLineItem> oli_map = new Map<ID,OpportunityLineItem>();
        for(OpportunityLineItem oli : oli_list) {
            oli_map.put(oli.CaseProductObject__c, oli);
        }

        //Create a list for updating current opps
        List<Opportunity> curr_opps = new List<Opportunity>();

        for(Case c : casesWithOpps) {
           Opportunity opp = caseId_opp_map.get(c.Id);
           opp.Rabatt_kommentar__c = c.Kommentar__c;
           opp.Best_llt_av__c = c.ContactId;
           opp.Information_om_s_ljprojekt__c = c.Description;
           curr_opps.add(opp);
        }
        if(curr_opps.size() > 0) {
          //  System.debug('curr_opps = ' + curr_opps);
            update curr_opps;
        }

        //Create a list for updating current OpportunityLineItems
        List<OpportunityLineItem> curr_oli_list = new List<OpportunityLineItem>();

        //Create a list for inserting new OpportunityLineItems
        List<OpportunityLineItem> new_oli_list = new List<OpportunityLineItem>();

        if(cpo_list_1.size() > 0) {
            for(CaseProductObject__c cpo : cpo_list_1) {
                if(oli_map.containskey(cpo.id)) {
                    OpportunityLineItem oli = oli_map.get(cpo.id);
                    oli.Quantity = cpo.Antal__c > 0 ? cpo.Antal__c : 1.0;
                    oli.UnitPrice = cpo.Enhetspris__c;
                    curr_oli_list.add(oli);
                }
                else {
                    OpportunityLineItem oli = new OpportunityLineItem();
                    oli.OpportunityId = caseId_opp_map.get(cpo.Case__c).id;
                    oli.PricebookEntryId = cpo.PriceBookEntry__c;
                    oli.Quantity = cpo.Antal__c > 0 ? cpo.Antal__c : 1.0;
                    oli.UnitPrice = cpo.Enhetspris__c;
                    oli.CaseProductObject__c = cpo.id;
                    oli.Discount = 0;
                    new_oli_list.add(oli);
                }
            }
            if(new_oli_list.size() > 0) insert new_oli_list;
            if(curr_oli_list.size() > 0) {
                System.debug('curr_oli_list = ' +curr_oli_list);
                update curr_oli_list;
            }
        }
    }

    // Create a list for the insert of opportunities
    List<Opportunity> opps = new List<Opportunity>();

    for(Integer i = 0; i < cases.size(); i++) {
        //Create a opportunity if case status is 'Stängt'
        if(cases[i].Status == 'Stängt' && !cases[i].hasOpportunity__c && cpo_list.size() > 0) {
            Opportunity opp = new Opportunity();
            opp.OwnerId = accId_Owner_map.get(cases[i].AccountID);
            opp.AccountId = cases[i].AccountId;
            opp.Name = cases[i].Subject + '_' + String.valueOf(date.today());
            opp.Type = 'Merförsäljning';
            opp.Source__c = 'Case';
            opp.StartDatum__c = cases[i].StartDate__c;
            opp.StageName = 'Väntar på godkännande';
            opp.CloseDate = cases[i].ClosedDate != null ? cases[i].ClosedDate.date() : date.today();
            opp.Case_Owner__c = cases[i].OwnerId;
            opp.Rabatt_kommentar__c = cases[i].Kommentar__c;
            opp.Case__c = cases[i].id;
            opp.Best_llt_av__c = cases[i].ContactId;
            opp.Information_om_s_ljprojekt__c = cases[i].Description;

            //Set that Case has a related opportunity
            cases[i].hasOpportunity__c = true;

            opps.add(opp);
        }
    }

    if(opps.size() > 0) insert opps;

    Map<ID,ID> caseId_oppId_map = new Map<ID,ID>();

    for(Opportunity opp : opps) {
        caseId_oppId_map.put(opp.Case__c, opp.Id);
    }

    //Create opportunity line items only if a new opportunity has been created
    if(opps.size() > 0) {

        List<OpportunityLineItem> oli_list = new List<OpportunityLineItem>();

        for(CaseProductObject__c cpo : cpo_list) {
            if(caseId_oppId_map.containsKey(cpo.Case__c)) {
                OpportunityLineItem oli = new OpportunityLineItem();
                oli.PricebookEntryId = cpo.PriceBookEntry__c;
                oli.OpportunityId = caseId_oppId_map.get(cpo.Case__c);
                oli.Quantity = cpo.Antal__c > 0 ? cpo.Antal__c : 1.0;
                oli.UnitPrice = cpo.Enhetspris__c;
                oli.CaseProductObject__c = cpo.id;
                oli.Discount = 0;
                oli_list.add(oli);
            }
        }
        if(oli_list.size() > 0) insert oli_list;
    }
}