public class PricingAttachment {
    @AuraEnabled
    public static void savePricingData(
        Id recordId, 
        String rawJson,
        String costRows,
        String inboundlog, 
        String seaFreightData,
        String inlandTransportData,
        String financialParams,
        String aopEbitda,
        String preEbitda,
        String indiaPro,
        String cmvPro,
        String package2040,
        String outboundlog
    ) {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Id = :recordId];
        opp.PricingRawJSON__c = rawJson;
        opp.PricingAdminJSON__c = costRows;
        opp.PricingInboundJSON__c = inboundlog;
        opp.PricingSeaFreightJSON__c = seaFreightData;
        opp.PricingInLandTranportJSON__c = inlandTransportData;
        opp.PricingFinanceJSON__c = financialParams;
        opp.PricingAOPJSON__c = aopEbitda;
        opp.PricingPreEbitdaJSON__c = preEbitda;
        opp.PricingIndiaProJSON__c = indiaPro;
        opp.PricingCMVProJSON__c = cmvPro;
        opp.PricingPackageJSON__c = package2040;
        opp.PricingOutboundJSON__c = outboundlog;
        update opp;
    }
    @AuraEnabled
    public static void generatePricingAttachment(
        Id recordId,
        Decimal finalPrice, 
        Decimal finalPriceinCent, 
        String fileName,
        String countrySource
    ) {
        
         Opportunity updatedOpp = [
                SELECT Id, Name, Owner.Name, National_Head_Approval__c, MD_Approval__c ,Approved_Date_Time__c
                FROM Opportunity 
                WHERE Id = :recordId
            ];
        PageReference pdfPage = Page.PricingAttachmentVFPage;
        pdfPage.getParameters().put('recordId', recordId);
        pdfPage.getParameters().put('finalPrice', String.valueOf(finalPrice));
        pdfPage.getParameters().put('finalPriceinCent', String.valueOf(finalPriceinCent));
        pdfPage.getParameters().put('countrySource', countrySource);
        pdfPage.getParameters().put('headApproval', updatedOpp.National_Head_Approval__c);
        pdfPage.getParameters().put('mdApproval', updatedOpp.MD_Approval__c);
        pdfPage.getParameters().put('approvedDateTime', String.valueOf(updatedOpp.Approved_Date_Time__c));
        
        
        Blob pdfBlob;
        try {
            pdfBlob = pdfPage.getContentAsPDF(); 
        } catch (VisualforceException e) {
            pdfBlob = Blob.valueOf('Error generating PDF');  
        }
        
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = fileName.replace('.pdf','');
        contentVersion.PathOnClient = fileName + '.pdf';
        contentVersion.VersionData = pdfBlob;
        insert contentVersion;
        
        
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId;
        ContentDocument cd = [Select Id,SharingPrivacy from ContentDocument where Id =: cdl.ContentDocumentId];
        cd.SharingPrivacy = 'P';
        Update cd;
        cdl.LinkedEntityId = recordId;
        cdl.ShareType = 'V';
        cdl.Visibility = 'SharedUsers';
        insert cdl;
        
        List<Profile> p = [Select Id,Name from Profile where Name = 'Key Accounts National Head' OR Name = 'Management Admin'];
        List<User> u = [Select Id,ProfileId from User where ProfileId In:p];
        System.debug('Users-->'+u);
        
        List<ContentDocumentLink> cdls = new List<ContentDocumentLink>();
        for(User uId:u){
            ContentDocumentLink link = new ContentDocumentLink();
            link.ContentDocumentId = cd.Id;
            link.LinkedEntityId = uId.Id;      
            link.ShareType = 'V';              
            link.Visibility = 'SharedUsers';   
            cdls.add(link);
        }
        if(!cdls.isEmpty()){
            Insert cdls;
        }
    }
    
    public class Request {
        @InvocableVariable(required=true)
        public Id recordId;
        
        @InvocableVariable(required=true)
        public Decimal finalPrice;
        
        @InvocableVariable(required=true)
        public Decimal finalPriceinCent;
        
        @InvocableVariable(required=true)
        public String fileName;
        
        @InvocableVariable(required=true)
        public String countrySource;
    }
    
    @InvocableMethod
    public static void generatePricingAttachmentwhenApproved(List<Request> requests) {
        for (Request req : requests) {
            // Your logic here, e.g.:
            System.debug('recordId: ' + req.recordId);
            System.debug('finalPrice: ' + req.finalPrice);
            System.debug('finalPriceinCent: ' + req.finalPriceinCent);
            System.debug('fileName: ' + req.fileName);
            System.debug('countrySource: ' + req.countrySource);
            
            Opportunity updatedOpp = [
                SELECT Id, Name, Owner.Name, National_Head_Approval__c, MD_Approval__c ,Approved_Date_Time__c
                FROM Opportunity 
                WHERE Id = :req.recordId
            ];
            
            System.debug('Latest Approval Status: ' + updatedOpp.National_Head_Approval__c + ' / ' + updatedOpp.MD_Approval__c);
            
                        
            PageReference pdfPage = Page.PricingAttachmentVFPage;
            pdfPage.getParameters().put('recordId', req.recordId);
            pdfPage.getParameters().put('finalPrice', String.valueOf(req.finalPrice));
            pdfPage.getParameters().put('finalPriceinCent', String.valueOf(req.finalPriceinCent));
            pdfPage.getParameters().put('countrySource', req.countrySource);
            pdfPage.getParameters().put('headApproval', updatedOpp.National_Head_Approval__c);
            pdfPage.getParameters().put('mdApproval', updatedOpp.MD_Approval__c);
            pdfPage.getParameters().put('approvedDateTime', String.valueOf(updatedOpp.Approved_Date_Time__c));
            
            
            Blob pdfBlob;
            try {
                pdfBlob = pdfPage.getContentAsPDF(); 
            } catch (VisualforceException e) {
                pdfBlob = Blob.valueOf('Error generating PDF');  
            }
            
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.Title = req.fileName.replace('.pdf','');
            contentVersion.PathOnClient = req.fileName + '.pdf';
            contentVersion.VersionData = pdfBlob;
            insert contentVersion;
            
            
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId;
            ContentDocument cd = [Select Id,SharingPrivacy from ContentDocument where Id =: cdl.ContentDocumentId];
            cd.SharingPrivacy = 'P';
            Update cd;
            cdl.LinkedEntityId = req.recordId;
            cdl.ShareType = 'V';
            cdl.Visibility = 'SharedUsers';
            insert cdl;
            
            List<User> users = [Select Id from User where UserRole.DeveloperName= 'National_Head_Key_Accounts_Private' OR UserRole.DeveloperName = 'Managing_Director'];
            System.debug('Users-->'+users);
            
            Set<Id> userIds = new Set<Id>();
            for(User u : users) {
                userIds.add(u.Id);
            }
            
            Set<Id> linkedUserIds = new Set<Id>();
            List<ContentDocumentLink> existingLinks = [SELECT Id,LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId = :cd.Id AND LinkedEntityId IN :userIds];
            
            for(ContentDocumentLink existingLink:existingLinks) {
                linkedUserIds.add(existingLink.LinkedEntityId);
            }
            
            List<ContentDocumentLink> cdlsToInsert = new List<ContentDocumentLink>();
            for(User u : users) {
                if(!linkedUserIds.contains(u.Id)) {
                    ContentDocumentLink newLink = new ContentDocumentLink();
                    newLink.ContentDocumentId = cd.Id;
                    newLink.LinkedEntityId = u.Id;
                    newLink.ShareType = 'V';
                    newLink.Visibility = 'SharedUsers';
                    cdlsToInsert.add(newLink);
                }
            }
            
            if(!cdlsToInsert.isEmpty()) {
                insert cdlsToInsert;
            }
        }
    }
}