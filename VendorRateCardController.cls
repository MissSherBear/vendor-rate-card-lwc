public with sharing class VendorRateCardController {
    // Get the Vendor Account from the Vendor_Account__c input field on the lightning web component
    // Declare the vendorAccountId variable
    public static Id vendorAccount;
    

    @AuraEnabled 
    public static void saveCongruexPricingRecords(List<Congruex_Vendor_Pricing__c> records) {

        if(records.size() > 0 && records != null) {
            List<Congruex_Vendor_Pricing__c> pricingRecordsToCreate = new List<Congruex_Vendor_Pricing__c>();

            for(integer i = 0; i < records.size(); i++) {
                Congruex_Vendor_Pricing__c cvp = new Congruex_Vendor_Pricing__c();
                cvp.Id = records[i].Id;
                cvp.Account__c = vendorAccount;
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
            SELECT Id, Name, BU__c 
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
    public static Account getVendorAccount(Id vendorAccount) {
        return [
            SELECT Id, Name, OU__c 
            FROM Account 
            WHERE Id = :vendorAccount
        ];
    }

    // Get the Vendor Account Name 
    @AuraEnabled
    public static String getVendorAccountName(Id vendorAccount) {
        return getVendorAccount(vendorAccount).Name;
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
    public static String getVendorAccountOu(Id vendorAccount) {
        return getVendorAccount(vendorAccount).OU__c;
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
    public static List<Map<String, Object>> createVendorRateCardWithItems(
        Id projectPriceBookId,
        Id vendorAccount,
        String contractUrl,
        String paymentTerms,
        String ou,
        List<Map<String, Object>> editedRows
    ) {
        System.debug('========================================THIS IS THE START OF THE CREATE VENDOR RATE CARD METHOD========================================');
        System.debug('projectPriceBookId: ' + projectPriceBookId);
        System.debug('vendorAccount: ' + vendorAccount);
        System.debug('vendorRateCardName: ' + getVendorAccountName(vendorAccount) + ' - ' + getProjectPriceBookName(projectPriceBookId));
        System.debug('contractUrl: ' + contractUrl);
        System.debug('paymentTerms: ' + paymentTerms);
        System.debug('ou: ' + ou);

        // Create a new Vendor Rate Card record
        Vendor_Rate_Card__c vendorRateCard = new Vendor_Rate_Card__c();
        vendorRateCard.Project_Price_Book__c = projectPriceBookId;
        vendorRateCard.Vendor_Account__c = vendorAccount;

        String vendorRateCardName = getVendorAccountName(vendorAccount) + ' - ' + getProjectPriceBookName(projectPriceBookId);
        vendorRateCard.Name = (vendorRateCardName.length() > 80) ? vendorRateCardName.left(80) : vendorRateCardName;
        vendorRateCard.Link_to_Contract__c = contractUrl;
        vendorRateCard.Payment_Terms__c = paymentTerms;
        // vendorRateCard.OU__c = ou;

        System.debug('vendorRateCard before insert: ' + vendorRateCard);

        insert vendorRateCard;

        System.debug('vendorRateCard: ' + vendorRateCard);
        System.assertEquals(vendorRateCard.Vendor_Account__c, vendorAccount);

        // Return the created pricing rows (with Names) for confirmation screen
        return createCongruexPricingRecords(vendorAccount, editedRows, vendorRateCard);
    }

    @AuraEnabled
    public static List<Map<String, Object>> createCongruexPricingRecords(
        Id vendorAccount,
        List<Map<String, Object>> editedRows,
        Vendor_Rate_Card__c vendorRateCard
    ) {
        System.debug('========================================THIS IS THE START OF THE CREATE CONGRUEX PRICING RECORDS METHOD========================================');
        System.debug('editedRows: ' + editedRows);
        System.debug('vendorAccount: ' + vendorAccount);

        System.debug('editedRows: ' + JSON.serialize(editedRows));

        List<Congruex_Vendor_Pricing__c> vendorPricingList = new List<Congruex_Vendor_Pricing__c>();
        Map<Id, Map<String, Object>> rowByPriceBookItemId = new Map<Id, Map<String, Object>>();

        for (Map<String, Object> editedRow : editedRows) {
            String priceBookItemIdStr = (String)editedRow.get('priceBookItemId');
            Id priceBookItemId = (priceBookItemIdStr == null) ? null : (Id)priceBookItemIdStr;

            String priceBookItemName = (String)editedRow.get('priceBookItemName');
            String description = (String)editedRow.get('description');
            String uom = (String)editedRow.get('uom');

            Object rawValue = editedRow.get('congruexVendorPrice');
            Decimal congruexVendorPrice;

            if (rawValue == null) {
                congruexVendorPrice = null;
            } else if (rawValue instanceof Decimal) {
                congruexVendorPrice = (Decimal)rawValue;
            } else if (rawValue instanceof Integer) {
                congruexVendorPrice = Decimal.valueOf((Integer)rawValue);
            } else if (rawValue instanceof Long) {
                congruexVendorPrice = Decimal.valueOf((Long)rawValue);
            } else if (rawValue instanceof String) {
                String strVal = (String)rawValue;
                congruexVendorPrice = String.isBlank(strVal) ? null : Decimal.valueOf(strVal);
            } else {
                throw new AuraHandledException('Unexpected value type for congruexVendorPrice: ' + rawValue);
            }

            // Create pricing record
            Congruex_Vendor_Pricing__c vendorPricing = new Congruex_Vendor_Pricing__c(
                Price_Book_Item__c = priceBookItemId,
                Cost__c = congruexVendorPrice,
                Account__c = vendorAccount,
                Vendor_Rate_Card__c = vendorRateCard.Id
            );

            vendorPricingList.add(vendorPricing);

            // Save original row details so we can return them after insert/query
            Map<String, Object> rowInfo = new Map<String, Object>();
            rowInfo.put('priceBookItemId', priceBookItemIdStr);
            rowInfo.put('priceBookItemName', priceBookItemName);
            rowInfo.put('description', description);
            rowInfo.put('uom', uom);
            rowInfo.put('congruexVendorPrice', congruexVendorPrice);

            if (priceBookItemId != null) {
                rowByPriceBookItemId.put(priceBookItemId, rowInfo);
            }

            System.debug('vendorPricingList (building): ' + vendorPricingList);
        }

        // Insert all pricing records
        insert vendorPricingList;

        System.debug('vendorPricingList (after insert): ' + vendorPricingList);
        System.debug('vendorRateCardName: ' + vendorRateCard.Name);
        System.debug('vendorRateCardId: ' + vendorRateCard.Id);

        // Collect inserted Ids safely
        Set<Id> insertedIds = new Set<Id>();
        for (Congruex_Vendor_Pricing__c vp : vendorPricingList) {
            if (vp.Id != null) insertedIds.add(vp.Id);
        }
        System.debug('insertedIds: ' + insertedIds);

        // Query back Name (and related fields if you want)
        List<Congruex_Vendor_Pricing__c> insertedVendorPricings = [
            SELECT Id, Name, Price_Book_Item__c, Cost__c
            FROM Congruex_Vendor_Pricing__c
            WHERE Id IN :insertedIds
        ];
        System.debug('insertedVendorPricings: ' + insertedVendorPricings);

        // Build return payload for LWC confirmation screen
        List<Map<String, Object>> exposedEditedRows = new List<Map<String, Object>>();

        for (Congruex_Vendor_Pricing__c vp : insertedVendorPricings) {
            Map<String, Object> baseRow = (vp.Price_Book_Item__c != null)
                ? rowByPriceBookItemId.get(vp.Price_Book_Item__c)
                : null;

            Map<String, Object> exposedRow = new Map<String, Object>();
            exposedRow.put('congruexVendorPricingId', vp.Id);
            exposedRow.put('congruexVendorPricingName', vp.Name);
            exposedRow.put('congruexVendorPrice', vp.Cost__c);
            exposedRow.put('vendorRateCardId', vendorRateCard.Id);
            exposedRow.put('vendorRateCardName', vendorRateCard.Name);

            if (baseRow != null) {
                exposedRow.put('priceBookItemId', (String)baseRow.get('priceBookItemId'));
                exposedRow.put('priceBookItemName', (String)baseRow.get('priceBookItemName'));
                exposedRow.put('description', (String)baseRow.get('description'));
                exposedRow.put('uom', (String)baseRow.get('uom'));
            } else {
                exposedRow.put('priceBookItemId', vp.Price_Book_Item__c);
            }

            exposedEditedRows.add(exposedRow);
        }

        System.debug('exposedEditedRows: ' + exposedEditedRows);
        System.debug('exposedEditedRows JSON: ' + JSON.serialize(exposedEditedRows));

        return exposedEditedRows;
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

    public class VendorRateCardResult {
        @AuraEnabled public String vendorRateCardId;
        @AuraEnabled public List<Congruex_Vendor_Pricing__c> createdPricings;
    }
    
}
