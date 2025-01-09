public with sharing class VendorRateCardController {
    // Get the Vendor Account from the Vendor_Account__c input field on the lightning web component
    // Declare the vendorAccountId variable
    public static Id vendorAccountId;

    @AuraEnabled 
    public static void saveCongruexPricingRecords(List<Congruex_Vendor_Pricing__c> records) {

        if(records.size() > 0 && records != null) {
            List<Congruex_Vendor_Pricing__c> pricingRecordsToCreate = new List<Congruex_Vendor_Pricing__c>();

            for(integer i = 0; i < records.size(); i++) {
                Congruex_Vendor_Pricing__c cvp = new Congruex_Vendor_Pricing__c();
                cvp.Id = records[i].Id;
                cvp.Account__c = vendorAccountId;
                cvp.Price_Book_Item__c = records[i].Price_Book_Item__c;
                cvp.Cost__c = records[i].Cost__c;
                pricingRecordsToCreate.add(cvp);
            }
            insert pricingRecordsToCreate;
        }

    }

    // get the current Project Price Book record from the current page
    // get the related Price Book Item records from the current recordId
    public static sitetracker__Project_Price_Book__c getProjectPriceBook(Id recordId) {
        return [
            SELECT Id, Name 
            FROM sitetracker__Project_Price_Book__c 
            WHERE Id = :recordId
        ];
    }

    @AuraEnabled(cacheable=true)
    public static sitetracker__Project_Price_Book__c getProjectPriceBookWithItems(Id recordId) {
        return [
            SELECT Id, Name, 
                (SELECT Id, Name, Price_Book_Name__c, sitetracker__Project_Price_Book__c, sitetracker__Description__c, UOM__c, Price_Per_Unit__c, External_Labor_Cost__c, Sort__c, Price_Book_Item_Status__c, IsActive__c
                 FROM sitetracker__Price_Book_Items__r
                 WHERE IsActive__c = true AND Price_Book_Item_Status__c = 'Effective'
                 ORDER BY Sort__c ASC)
            FROM sitetracker__Project_Price_Book__c 
            WHERE Id = :recordId
        ];
    }

    // Get the Vendor Account from the Vendor_Account__c input field on the lightning web component
    @AuraEnabled
    public static Account getVendorAccountId(Id vendorAccountId) {
        return [
            SELECT Id, Name 
            FROM Account 
            WHERE Id = :vendorAccountId
        ];
    }

    // Get the Vendor Account Name 
    @AuraEnabled
    public static String getVendorAccountName(Id vendorAccountId) {
        return getVendorAccountId(vendorAccountId).Name;
    }

    // Get the Project Price Book Name
    @AuraEnabled
    public static String getProjectPriceBookName(Id recordId) {
        return getProjectPriceBook(recordId).Name;
    }

    // Get the Project Price Book BU 
    @AuraEnabled
    public static String getProjectPriceBookBU(Id recordId) {
        return getProjectPriceBook(recordId).BU__c;
    }
    


    // Get the payment terms from the Payment_Terms__c input field on the lightning web component
    @AuraEnabled
    public static String getPaymentTerms(String paymentTerms) {
        return paymentTerms;
    }

    @AuraEnabled
    public static String getContractUrl(String contractUrl) {
        return contractUrl;
    }

    @AuraEnabled
    public static String getOU(String ou) {
        return ou;
    }


    // private static List<CongruexPricingRecord> createCongruexPricingObjects(List<Congruex_Vendor_Pricing__c> pricingRecords) {
    //     List<CongruexPricingRecord> pricings = new List<CongruexPricingRecord>();
    //     for(Congruex_Vendor_Pricing__c pricingRecord : pricingRecords) {
    //         pricings.add(new CongruexPricingRecord() 
    //             .setPriceBookItemId(pricingRecord.Price_Book_Item__c)
    //             .setCongruexVendorPricing(pricingRecord.congruexVendorPrice)
    //             .setVendorAccountId(pricingRecord.Vendor_Account__c)
    //             .setVendorRateCard(new Vendor_Rate_Card__c(
    //                 Project_Price_Book__c = pricingRecord.Project_Price_Book__c,
    //                 Vendor_Account__c = pricingRecord.Vendor_Account__c,
    //                 Name = 'Vendor Rate Card' + pricingRecord.Vendor_Account__r.Name + ' - ' + pricingRecord.Project_Price_Book__r.Name
    //             ))
    //         );
    //         return pricings;
    //     }
    // }


    // Create a new Vendor Rate Card record from the lightning web component input fields and the current Project Price Book record  
    // @AuraEnabled
    // public static void createVendorRateCard() {
    //     // Create a new Vendor Rate Card record
    //     Congruex_Vendor_Rate_Card__c vendorRateCard = new Congruex_Vendor_Rate_Card__c() {
    //         Name = 'Vendor Rate Card' + getVendorAccount().Name + ' - ' + getProjectPriceBook().Name,
    //         Project_Price_Book__c = getProjectPriceBook().Id,
    //         Vendor_Account__c = getVendorAccount().Id
    //     };

    //     // Insert the new Vendor Rate Card record
    //     insert vendorRateCard;
    // }

    // @AuraEnabled
    // public static void createVendorRateCard(Id projectPriceBookId, Id vendorAccountId) {
    //     // Create a new Vendor Rate Card record
    //     Congruex_Vendor_Rate_Card__c vendorRateCard = new Congruex_Vendor_Rate_Card__c();
    //     vendorRateCard.Name = 'Vendor Rate Card' + getVendorAccount(vendorAccountId).Name + ' - ' + getProjectPriceBook(projectPriceBookId).Name;
    //     vendorRateCard.Project_Price_Book__c = projectPriceBookId;
    //     vendorRateCard.Vendor_Account__c = vendorAccountId;

    //     // Insert the new Vendor Rate Card record
    //     insert vendorRateCard;

    //     // Create a new Congruex Vendor Pricing record for each row that was edited in the LWC datatable and add it to the Vendor Rate Card

        
    // }

    @AuraEnabled
    public static void createVendorRateCardWithItems(Id projectPriceBookId, Id vendorAccount, String contractUrl, String paymentTerms, String ou, List<Map<String, Object>> editedRows) {
        System.debug('========================================THIS IS THE START OF THE CREATE VENDOR RATE CARD METHOD========================================');
        System.debug('projectPriceBookId: ' + projectPriceBookId);
        System.debug('vendorAccountId: ' + vendorAccount);
        System.debug('contractUrl: ' + contractUrl);
        System.debug('paymentTerms: ' + paymentTerms);
        System.debug('ou: ' + ou);
        // Create a new Vendor Rate Card record
        Vendor_Rate_Card__c vendorRateCard = new Vendor_Rate_Card__c();
        vendorRateCard.Project_Price_Book__c = projectPriceBookId;
        vendorRateCard.Vendor_Account__c = vendorAccount;
        vendorRateCard.Name = getVendorAccountName(vendorAccount) + ' - ' + getProjectPriceBookName(projectPriceBookId);
        vendorRateCard.Link_to_Contract__c = contractUrl;
        vendorRateCard.Payment_Terms__c = paymentTerms;
        // vendorRateCard.OU__c = ou;

        // Insert the new Vendor Rate Card record
        insert vendorRateCard;
        System.debug('vendorRateCard: ' + vendorRateCard);
        System.assertEquals(vendorRateCard.Vendor_Account__c, vendorAccount);

        // Create a new Congruex Vendor Pricing record for each row that was edited in the LWC datatable and add it to the Vendor Rate Card
        createCongruexPricingRecords(vendorAccount, editedRows, vendorRateCard);
    }

    // Get the list of edited rows of Price Book Items from the LWC datatable. Then create a new child Congruex Vendor Pricing record for each row
    @AuraEnabled
    public static void createCongruexPricingRecords(Id vendorAccount, List<Map<String, Object>> editedRows, Vendor_Rate_Card__c vendorRateCard) {
        System.debug('========================================THIS IS THE START OF THE CREATE CONGRUEX PRICING RECORDS METHOD========================================');    
        System.debug('editedRows: ' + editedRows);
        System.debug('vendorAccount: ' + vendorAccount);
        System.debug('editedRows: ' + JSON.serialize(editedRows));
        List<Congruex_Vendor_Pricing__c> vendorPricingList = new List<Congruex_Vendor_Pricing__c>();
        List<Map<String, Object>> exposedEditedRows = new List<Map<String, Object>>();
        for(Map<String, Object> editedRow: editedRows) {
            // Extract relevant field values from the edited row map
            String priceBookItemId = (String)editedRow.get('priceBookItemId');
            String priceBookItemName = (String)editedRow.get('priceBookItemName');
            String description = (String)editedRow.get('description');
            String uom = (String)editedRow.get('uom');
            // Decimal pricePerUnit = (Decimal)editedRow.get('pricePerUnit');
            // Decimal congruexVendorPrice = (Decimal)editedRow.get('congruexVendorPrice');
            Decimal congruexVendorPrice = Decimal.valueOf((String)editedRow.get('congruexVendorPrice'));
           
            // Create a new Congruex Vendor Pricing record and populate the fields
            Congruex_Vendor_Pricing__c vendorPricing = new Congruex_Vendor_Pricing__c (

                Price_Book_Item__c = priceBookItemId,
                Cost__c = congruexVendorPrice,
                Account__c = vendorAccount,
                Vendor_Rate_Card__c = vendorRateCard.Id
            ); 

            // Add the new Congruex Vendor Pricing record to the list
            vendorPricingList.add(vendorPricing);
            System.debug('vendorPricingList: ' + vendorPricingList);

            // Create a map to expose the relevant fields to the LWC datatable
            Map<String, Object> exposedRow = new Map<String, Object>();
            exposedRow.put('priceBookItemId', priceBookItemId);
            exposedRow.put('priceBookItemName', priceBookItemName);
            exposedRow.put('description', description);
            exposedRow.put('uom', uom);
            // exposedRow.put('pricePerUnit', pricePerUnit);

            // Add the exposed row to the list of exposed edited rows
            exposedEditedRows.add(exposedRow);
            System.debug('exposedEditedRows: ' + exposedEditedRows);
            System.debug('exposedEditedRows: ' + JSON.serialize(exposedEditedRows));

        }

        // Insert the list of new Congruex Vendor Pricing records
        insert vendorPricingList;

        // Return the list of exposed edited rows to the LWC datatable
        // return exposedEditedRows;



    }

    // Get the Vendor Account from the Vendor_Account__c input field on the lightning web component
    // @AuraEnabled
    // public static Account getVendorAccount(Id vendorAccountId) {
    //     Account vendorAccountId;
    //     try {
    //         vendorAccountId = [
    //             SELECT Id, Name 
    //             FROM Account 
    //             WHERE Id = :vendorAccountId
    //         ];
    //     } catch (Exception e) {
    //         System.debug('Error fetching Account:  ' + e.getMessage());
    //     }
    //     return vendorAccountId;
    // }

    







    // // get the child Price Book Items related to the current Project Price Book
    // @AuraEnabled
    // public static List<sitetracker__Pricebook_Item__c> getPriceBookItems() {
    //     return [SELECT Id, Name, Price_Book_Name__c, sitetracker__Description__c, UOM__c, Price_Per_Unit__c 
    //             FROM sitetracker__Pricebook_Item__c
    //             WHERE sitetracker__Project_Price_Book__c = :projectPriceBook.Id];
    // }
    


    // @AuraEnabled
    // public static List<sitetracker__Pricebook_Item__c> getPriceBookItems(Id projectPriceBookId) {
    //     return [SELECT Id, Name, Price_Book_Name__c, sitetracker__Description__c, UOM__c, Price_Per_Unit__c 
    //             FROM sitetracker__Pricebook_Item__c
    //             WHERE sitetracker__Project_Price_Book__c = :projectPriceBookId];
    // }

    // If the Price Book Item is selected, create 



//     // get the Price Book Items related to the current Vendor Rate Card
//     public static List<sitetracker__Pricebook_Item__c> getPriceBookItems(String sitetracker__Project_Price_Book__c) {
//         return [SELECT Id, Name, Price_Book_Name__c, sitetracker__Description__c, UOM__c, Price_Per_Unit__c 
//                 FROM sitetracker__Pricebook_Item__c
//                 WHERE sitetracker__Project_Price_Book__c = :getVendorRateCard.Project_Price_Book__c];
//    }

   // Search for Price Book Items to add to the Vendor Rate Card

    // public static List<sitetracker__Pricebook_Item__c> getSearchedPriceBookItems(String sitetracker__Project_Price_Book__c, String searchKey) {
    //       return [SELECT Id, Name, Price_Book_Name__c, sitetracker__Description__c, UOM__c, Price_Per_Unit__c 
    //               FROM sitetracker__Pricebook_Item__c
    //               WHERE sitetracker__Project_Price_Book__c = :sitetracker__Project_Price_Book__c 
    //               AND Name LIKE :searchKey];
    // }

    // For each Price Book Item added, create child Congruex Vendor Pricing records for each row related to the Vendor Rate Card
    public static void addPriceBookItems(List<sitetracker__Pricebook_Item__c> priceBookItems, Id vendorRateCardId) {
        List<Congruex_Vendor_Pricing__c> vendorPricingList = new List<Congruex_Vendor_Pricing__c>();
        for(sitetracker__Pricebook_Item__c priceBookItem : priceBookItems) {
            Congruex_Vendor_Pricing__c vendorPricing = new Congruex_Vendor_Pricing__c();
            vendorPricing.Vendor_Rate_Card__c = vendorRateCardId;
            vendorPricing.Price_Book_Item__c = priceBookItem.Id;
            vendorPricingList.add(vendorPricing);
        }
        insert vendorPricingList;
    }
}
