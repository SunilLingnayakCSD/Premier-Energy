global without sharing class SAPInvoiceBatchController implements Database.Batchable<SAPInvoiceBatchController.InvoiceWrapper>, Database.AllowsCallouts {

    global class InvoiceWrapper {
        public String invoiceNumber;
        public String salesOrderNumber;
        public String documentType;
        public String invoiceDate;
        public String salesDocNo;
        public List<LineItemWrapper> lineItems;
    }

    global class LineItemWrapper {
        public String materialNumber;
        public String materialDescription;
        public String quantity;
        public String quantityUnit;
        public String amount;
        public String amountCurrency;
        public String discount;
        public String cgst;
        public String sgst;
        public String igst;
    }

    private List<InvoiceWrapper> allInvoices;

    public SAPInvoiceBatchController(List<InvoiceWrapper> invoices) {
        this.allInvoices = invoices;
    }

    global Iterable<InvoiceWrapper> start(Database.BatchableContext context) {
        return allInvoices;
    }

    global void execute(Database.BatchableContext context, List<InvoiceWrapper> scope) {
        Set<String> orderNos = new Set<String>();
        Set<String> invoiceNos = new Set<String>();
        Set<String> matNumbers = new Set<String>();

        for (InvoiceWrapper inv : scope) {
            orderNos.add(inv.salesOrderNumber);
            invoiceNos.add(inv.invoiceNumber);
            if (inv.lineItems != null) {
                for (LineItemWrapper li : inv.lineItems) {
                    if (li.materialNumber != null)
                        matNumbers.add(li.materialNumber);
                }
            }
        }

       /* Map<String, Id> orderToAccount = new Map<String, Id>();
        for (Order o : [
            SELECT Id, AccountId, SAP_Order_Id__c
            FROM Order
            WHERE SAP_Order_Id__c IN :orderNos
        ]) orderToAccount.put(o.SAP_Order_Id__c, o.AccountId);*/
        
        Map<String, Id> orderToAccount = new Map<String, Id>();
        Map<String, Id> orderIdMap = new Map<String, Id>(); // <-- new map for Order Id
        
        for (Order o : [
            SELECT Id, AccountId, SAP_Order_Id__c
            FROM Order
            WHERE SAP_Order_Id__c IN :orderNos
        ]) {
            orderToAccount.put(o.SAP_Order_Id__c, o.AccountId);
            orderIdMap.put(o.SAP_Order_Id__c, o.Id); // <-- save Order.Id
        }

        Map<String, Id> productMap = new Map<String, Id>();
        for (Product2 p : [
            SELECT Id, Material_Number__c
            FROM Product2
            WHERE Material_Number__c IN :matNumbers
        ]) productMap.put(p.Material_Number__c, p.Id);

        Map<String, Invoice__c> existing = new Map<String, Invoice__c>();
        for (Invoice__c inv : [
            SELECT Id, Invoice_Number__c
            FROM Invoice__c
            WHERE Invoice_Number__c IN :invoiceNos
        ]) existing.put(inv.Invoice_Number__c, inv);

        System.debug('>>> Existing Invoices Found: ' + existing.keySet());

        List<Invoice__c> toInsert = new List<Invoice__c>();
        List<Invoice__c> toUpdate = new List<Invoice__c>();
        Map<String, List<Invoice_Line_Item__c>> lineMap = new Map<String, List<Invoice_Line_Item__c>>();

        for (InvoiceWrapper wrap : scope) {
            Id acctId = orderToAccount.get(wrap.salesOrderNumber);
            if (acctId == null) continue; // skip if order not found

            Boolean isCancel = wrap.documentType == 'Invoice Cancellation';
            Boolean isExisting = existing.containsKey(wrap.invoiceNumber);

            System.debug('>>> Processing Invoice: ' + wrap.invoiceNumber + ' | isExisting: ' + isExisting + ' | isCancel: ' + isCancel);

            Invoice__c inv = isExisting ? existing.get(wrap.invoiceNumber)
                                        : new Invoice__c(Account__c = acctId);

            inv.Name = wrap.salesDocNo;
            inv.Invoice_Number__c = wrap.invoiceNumber;
            inv.Document_Type__c = wrap.documentType;
            inv.Is_Cancellation__c = isCancel;
            inv.Order__c = orderIdMap.get(wrap.salesOrderNumber); 

            if (!String.isBlank(wrap.invoiceDate)) {
                try {
                    inv.Invoice_Date__c = Date.valueOf(wrap.invoiceDate.trim());
                } catch (Exception e) {
                    System.debug('>>> Invalid date for invoice: ' + wrap.invoiceNumber);
                }
            }

            if (isExisting) {
                System.debug('>>> Adding to Update: ' + inv.Invoice_Number__c);
                toUpdate.add(inv);
            } else {
                System.debug('>>> Adding to Insert: ' + inv.Invoice_Number__c);
                toInsert.add(inv);
            }

            // Skip line items if cancellation of already existing invoice
            if (!isCancel || (isCancel && !isExisting)) {
                List<Invoice_Line_Item__c> lines = new List<Invoice_Line_Item__c>();
                for (LineItemWrapper line : wrap.lineItems) {
                    Invoice_Line_Item__c lli = new Invoice_Line_Item__c(
                        Product__c = productMap.get(line.materialNumber),
                        Material_Description__c = line.materialDescription,
                        Quantity__c = tryDecimal(line.quantity),
                        Quantity_Unit__c = line.quantityUnit,
                        Amount__c = tryDecimal(line.amount),
                       // Amount_Currency__c = tryDecimal(line.amountCurrency),
                        Discount__c = tryDecimal(line.discount),
                        CGST__c = line.cgst,
                        SGST__c = line.sgst,
                        IGST__c = line.igst
                    );
                    lines.add(lli);
                }
                lineMap.put(wrap.invoiceNumber, lines);
            } else {
                System.debug('>>> Skipping line items for cancellation of existing invoice: ' + wrap.invoiceNumber);
            }
        }

        if (!toInsert.isEmpty()) {
            System.debug('>>> Inserting Invoices: ' + toInsert.size());
            insert toInsert;
        }
        if (!toUpdate.isEmpty()) {
            System.debug('>>> Updating Invoices: ' + toUpdate.size());
            for (Invoice__c u : toUpdate) {
                System.debug('>>> Updating Invoice: ' + u.Invoice_Number__c + ' | DocType: ' + u.Document_Type__c + ' | Cancel: ' + u.Is_Cancellation__c);
            }
            update toUpdate;
        }

        Map<String, Id> invoiceIdMap = new Map<String, Id>();
        for (Invoice__c inv : [
            SELECT Id, Invoice_Number__c
            FROM Invoice__c
            WHERE Invoice_Number__c IN :lineMap.keySet()
        ]) invoiceIdMap.put(inv.Invoice_Number__c, inv.Id);

        List<Invoice_Line_Item__c> allLines = new List<Invoice_Line_Item__c>();
        for (String invoiceNo : lineMap.keySet()) {
            Id invId = invoiceIdMap.get(invoiceNo);
            for (Invoice_Line_Item__c li : lineMap.get(invoiceNo)) {
                li.Invoice__c = invId;
                allLines.add(li);
            }
        }

        if (!allLines.isEmpty()) {
            System.debug('>>> Inserting Line Items: ' + allLines.size());
            insert allLines;
        }
    }

    global void finish(Database.BatchableContext context) {
        System.debug('>>> Batch Execution Finished.');
    }

    private static Decimal tryDecimal(String val) {
        try { 
            Decimal Va = String.isBlank(val) ? null : Decimal.valueOf(val); 
            System.debug('Va'+Va);
            
            try {
                Decimal d = Decimal.valueOf(val);
                System.debug(val + ' is a valid decimal.');
            } catch (Exception e) {
                System.debug(val + ' is NOT a valid decimal.');
            }
            return Va;
        }
        catch (Exception e) {
            System.debug('e expeception--------------------'+e);
             return null;
        }
    }

    public static List<InvoiceWrapper> parseJson(String jsonBody) {
        List<InvoiceWrapper> result = new List<InvoiceWrapper>();
        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(jsonBody);

        if (!parsed.containsKey('root')) {
            throw new CalloutException('Missing "root" key');
        }

        List<Object> rawList = (List<Object>) parsed.get('root');

        for (Object obj : rawList) {
            Map<String, Object> raw = (Map<String, Object>) obj;
            InvoiceWrapper wrap = new InvoiceWrapper();

            wrap.invoiceNumber    = String.valueOf(raw.get('SAP_Invoice_Number'));
            wrap.salesOrderNumber = String.valueOf(raw.get('SAP_Sales_Order_Number'));
            wrap.documentType     = String.valueOf(raw.get('Document_Type'));
            wrap.invoiceDate      = String.valueOf(raw.get('Invoice_Date'));
            wrap.salesDocNo       = String.valueOf(raw.get('Sales_Doc_No'));

            wrap.lineItems = new List<LineItemWrapper>();
            if (raw.containsKey('LineItems')) {
                for (Object lineObj : (List<Object>) raw.get('LineItems')) {
                    Map<String, Object> line = (Map<String, Object>) lineObj;
                    LineItemWrapper li = new LineItemWrapper();
                    li.materialNumber      = String.valueOf(line.get('Material_Number'));
                    li.materialDescription = String.valueOf(line.get('Material_Description'));
                    li.quantity            = String.valueOf(line.get('Quantity'));
                    li.quantityUnit        = String.valueOf(line.get('Quantity_Unit'));
                    li.amount              = String.valueOf(line.get('Amount'));
                    li.amountCurrency      = String.valueOf(line.get('Amount_Currency'));
                    li.discount            = String.valueOf(line.get('Discount'));
                    li.cgst                = String.valueOf(line.get('CGST'));
                    li.sgst                = String.valueOf(line.get('SGST'));
                    li.igst                = String.valueOf(line.get('IGST'));
                    wrap.lineItems.add(li);
                }
            }

            result.add(wrap);
        }

        return result;
    }
}