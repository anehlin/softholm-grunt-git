public class CaseProductController {

    public Case c { get; private set; }
    public String selectedProduct { get;set; }
    public ID selectedPricebook { get;set; }
    private ID selectedPriceBookEntry { get; set; }
    private Decimal unitPrice { get; set; }
    public Boolean hasNotAddedProduct { get; set; }
    private String productName { get; set; }
    private String unitType { get; set; }

    public CaseProductController() {  
        
        this.c = [SELECT Id, Status, Subject, StartDate__c, AccountId, Antal__c FROM Case 
                   WHERE Id = :ApexPages.currentPage().getParameters().get('id')];  
                    
        this.c.StartDate__c = null;
        this.c.Antal__c = null;
        
        List<Pricebook2> p_book = [SELECT Id FROM Pricebook2
                                  Where Name = 'Standard Price Book'];
        this.selectedPricebook = p_book.get(0).id;
        hasNotAddedProduct = true;
    }
    
    public void checkProductChoice() {       
        hasNotAddedProduct = this.selectedProduct != null ? false : true;
    }
    
     public List<selectOption> getPriceBooks() {
     
        List<selectOption> options = new List<selectOption>(); 
     
        List<CaseProductObject__c> cpo_list = [Select id, PriceBookEntry__c 
                                               From CaseProductObject__c
                                               Where Case__c =: this.c.id];
         
        List<Pricebook2> pb = new List<Pricebook2>();
                                              
        if(cpo_list.size() > 0) {
            List<PricebookEntry> pbe = [SELECT  Pricebook2Id, Id, Name
                                        FROM PricebookEntry
                                        Where Id =: cpo_list.get(0).PriceBookEntry__c];
            pb = [SELECT Id, Name FROM Pricebook2
                  Where id =: pbe.get(0).Pricebook2Id];
        }
        else {
            pb = [SELECT Id, Name FROM Pricebook2];      
         }
         
        for(Pricebook2 p : pb) {
            options.add(new SelectOption(p.Id,p.Name));
        }  
         
         return options;  
     }
    
     public List<selectOption> getProducts() {
        List<selectOption> options = new List<selectOption>();
        
        List<CaseProductObject__c> cpo_list = [Select id, PriceBookEntry__c 
                                               From CaseProductObject__c
                                               Where Case__c =: this.c.id];

        ID pricebookId = null;

        if(cpo_list.size() > 0) {
            List<PricebookEntry> pbe_list = [SELECT  Pricebook2.Id FROM PricebookEntry
                                            Where Id =: cpo_list.get(0).PriceBookEntry__c];
            pricebookId = pbe_list.get(0).Pricebook2.Id;
        }
        else {
             pricebookId = this.selectedPricebook;      
         }

        List<PricebookEntry> pbe = [SELECT Product2Id, Pricebook2Id, ProductCode, Pricebook2.Name,
                            Product2.Charging_period__c, Id, Name, UnitPrice
                            FROM PricebookEntry
                            Where IsActive = true
                            And Pricebook2.Id =: pricebookId];

        String optionName = pbe.size() > 0 ? 'Välj produkt från ' + pbe.get(0).Pricebook2.Name :
                                             'Produkter saknas';

        SelectOption firstOption = new SelectOption('', optionName);
        options.add(firstOption);

        if(pbe.size() > 0) {
            for(PricebookEntry p : pbe) {
                String label = p.Name + ' - ' + p.UnitPrice + p.Product2.Charging_period__c;
                options.add(new SelectOption(p.Product2Id, label));
             }
         }
         return options;
     }
     
     private void updatePriceBookEntry(ID selectedProduct) {
       
       List<PriceBookEntry> m_pbe = [SELECT Product2Id, Pricebook2Id, ProductCode, Pricebook2.Name,
                                        Product2.Charging_period__c, Id, Name, UnitPrice
                                        FROM PricebookEntry
                                        Where IsActive = true
                                        And Pricebook2.Id =: this.selectedPricebook
                                        And Product2Id =: selectedProduct ];
      this.selectedPriceBookEntry = m_pbe.get(0).id;
      this.unitPrice = m_pbe.get(0).UnitPrice; 
      this.productName = m_pbe.get(0).Name; 
      this.unitType = m_pbe.get(0).Product2.Charging_period__c;                                                      
    }
     
    public PageReference updatePriceBook() {
        this.getProducts();
        return null;
    }

    public PageReference cancel() {
        
        PageReference pageRef = new PageReference('/'+ this.c.id);
        pageRef.setRedirect(true);

        return pageRef;
    }

    public PageReference saveAndAddProduct() {
    
        updatePriceBookEntry(this.selectedProduct);
        
         try{
            CaseProductObject__c cpo = new CaseProductObject__c();
            cpo.Name = this.productName;
            cpo.StartDatum__c = this.c.StartDate__c;
            cpo.Antal__c = this.c.Antal__c > 0 ? this.c.Antal__c : 1.0;
            cpo.Enhetspris__c = this.unitPrice;
            cpo.Enhet__c = this.unitType;
            cpo.PriceBookEntry__c = this.selectedPriceBookEntry;
            cpo.Case__c = this.c.id;
            cpo.Product__c = this.selectedProduct;
            insert cpo;
            update this.c;            
        }        
        catch(Exception e){
            ApexPages.addmessage(new ApexPages.message(ApexPages.Severity.ERROR,'Error creating/updating record'));
        }
         
        PageReference pageRef = new PageReference('/'+ this.c.id);
        pageRef.setRedirect(true);

        return pageRef;
    }

}