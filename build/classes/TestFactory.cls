public class TestFactory {

        // Returns a list of valid mock accounts
    public static List<Account> buildTestAccounts(Integer count) {    
        List<Account> accounts = new List<Account>();
        for(Integer i = 0; i < count; i++) {
            Account account = new Account();
            account.Name = 'Company_' + String.valueOf(i);
            account.Type = math.mod(i,2)==0 ? 'Prospekt' : 'Kund';
            if(i < 10){
                account.Org_nr__c = '123456-000' + String.valueOf(i);
            }
            if(i > 9 && i < 100){
                account.Org_nr__c = '123456-00' + String.valueOf(i);
            }
            if(i > 99 && i < 1000){
                account.Org_nr__c = '123456-0' + String.valueOf(i);
            }
            accounts.add(account);  
        }
        return accounts;
    }
    
    public static List<Contact> buildTestContacts(Integer count, List<Account> accounts) {
        
        List<Contact> contacts = new List<Contact>();
        for(Integer i = 0; i < count; i++) {
            Contact contact = new Contact();
            if(i < 10){
                contact.Personnummer__c = '123456-000' + String.valueOf(i);
            }
            if(i > 9 && i < 100){
                contact.Personnummer__c = '123456-00' + String.valueOf(i);
            }
            if(i > 99 && i < 1000){
                contact.Personnummer__c = '123456-0' + String.valueOf(i);
            }
            contact.FirstName = 'Nisse_' + String.valueOf(i);
            contact.LastName = math.mod(i,2)==0 ? 'Jansson_' + String.valueOf(i) : 'Carlsson_' + String.valueOf(i);
            contact.Phone = '+4612345698' + String.valueOf(i);
            contact.AccountId = i < accounts.size() ? accounts.get(i).id :accounts.get(0).id ;  
            contacts.add(contact);
        }
        return contacts;
    }
    
    // Returns a list valid mock opportunities
    public static List<Opportunity> buildTestOpportunities(Integer count, List<Account> accounts) {     
        List<Opportunity> opportunities = new List<Opportunity>();
        for(Integer i = 0; i < count; i++) {
            Opportunity opportunity = new Opportunity();
            opportunity.AccountId = i < accounts.size() ? accounts.get(i).id :accounts.get(0).id ;  
            opportunity.Name = 'MyTestOpp_' + String.valueOf(i);
            /*opportunity.CurrencyIsoCode = 'SEK';*/
            opportunity.Type = math.mod(i,2)==0 ? 'Renewal' : 'Upsell';
            opportunity.StageName = math.mod(i,2)==0 ? 'Regroup' : 'Closed Won';
            opportunity.LeadSource = 'PR';
            opportunity.CloseDate = date.today().addDays(10+i);
            opportunities.add(opportunity);
        } 
        return opportunities;
    }

    // Returns a list of valid mock Case objects
    public static List<Case> buildTestCases(Integer count, List<Account> accs, List<Contact> contacts) {
        List<Case> cases = new List<Case>();
        for(Integer i = 0; i < count; i++) {
            Case c = new Case();
            c.AccountId = i < accs.size() ? accs.get(i).id : accs.get(0).id;
            c.Origin = 'Email';
            c.Reason = 'New problem';
            c.ContactId = i < contacts.size() ? contacts.get(i).id : contacts.get(0).id;
            //c.Produktkategori__c = 'Tid';
            
            c.Status = 'Nytt'; 
            cases.add(c);
        }
        return cases;
    }
}