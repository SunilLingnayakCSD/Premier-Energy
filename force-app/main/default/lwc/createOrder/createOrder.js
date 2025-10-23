import { LightningElement, track, wire } from 'lwc';
// import userCounts from '@salesforce/apex/HomeOrderControllers.userCounts';

import getAccountForUser from '@salesforce/apex/HomeOrderControllers.getAccountForUser';

import countAndFetchOrdersByUser from '@salesforce/apex/HomeOrderControllers.countAndFetchOrdersByUser';
import checkPricingSchemes from '@salesforce/apex/HomeOrderControllers.checkPricingSchemes';
import getAllProducts from '@salesforce/apex/HomeOrderControllers.getAllProducts';
import getNewLeadsCountByUser from '@salesforce/apex/HomeOrderControllers.getNewLeadsCountByUser';
import getMetaData from '@salesforce/apex/HomeOrderControllers.getMetaData';
import getAccountAddressDetails from '@salesforce/apex/HomeOrderControllers.getAccountAddressDetails';
import USER_Id from '@salesforce/user/Id';
import getRelatedProducts from '@salesforce/apex/HomeOrderControllers.getRelatedProducts';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import logoPremier from '@salesforce/resourceUrl/logoPremier';
import createOrderFromJSON from '@salesforce/apex/HomeOrderControllers.createOrderFromJSON';
// Add this import to your existing imports at the top of your LWC JavaScript file
import getAllPricingConditions from '@salesforce/apex/HomeOrderControllers.getAllPricingConditions';

// Keep your existing import for backward compatibility if needed elsewhere
import getpricingCondition from '@salesforce/apex/HomeOrderControllers.getpricingCondition';


export default class CreateOrder extends LightningElement {
    logoPremier = logoPremier;

    @track model;
    @track ismodalopen;
    @track today;
    @track userId = USER_Id;
    @track accounts = [];
    @track acc;
    @track datarecords = [];
    @track draftValues = [];
    @track valueAccount = [];
    @track productOptions = [];
    @track selectedProductId = '';
    @track selectedProduct = null;
    @track quantity = 1;
    @track price = 0;
    @track total = 0;
    @track selectedRows = [];
    @track fullProductList = [];
    @track rowIdCounter = 1;
    @track grandTotal = 0;
    @track gstAmount = 0;
    @track tdsAmount = 0;
    @track netPayable = 0;
    @track finalPayable = 0;
    @track metarecords = [];
    @track uploadedFileName = '';
    @track ponum;
    @track orderCounts = { InTransit: 0, Closed: 0 };
    @track closedOrders = [];
    @track inTransitOrders = [];
    @track billto = [];
    @track shipTo = [];
    @track selectedbillto;
    @track accountsaddressDetails = [];
    @track selectedshipto;
    @track billtoOptions = [];
    @track shipToOptions = [];
    @track billingAddress;
    @track shippingAddress;
    @track shippingObj;
    @track billingObj;
    @track productIds;
    @track formattedPallets = 0;
    @track formattedQuantity = 0;
    @track formattedwptotal = 0;
    @track formattedMWptotal = 0;
    @track formattedTotalAmount = 0;
    @track formattedTdsAmount = 0;
    @track formattedGstAmount = 0;
    @track formattedGrandTotal = 0;
    @track formattedGrandTotalAmount = 0;
    @track dataload = false;

    handlePoNumChange(event) {
        this.ponum = event.target.value;
    }

    getDate() {
        const todayDate = new Date();
        this.today = todayDate.toISOString().split('T')[0];
    }

    @wire(getMetaData)
    allMetarecords(result) {
        if (result.data) {
            this.metarecords = result.data;
            this.getDate();
        } else if (result.error) {
            console.error('Error fetching products:', result.error.body.message);
        }
    }

    handleAccounts() {
        getAccountAddressDetails({ recordId: this.userId }).then(result => {
            console.log('OUTPUT : --result--', result);
            if (result) {
                this.accountsaddressDetails = result[0].Adresses__r != null ? result[0].Adresses__r : [];
                console.log('OUTPUT : --this.accountsaddressDetails--', this.accountsaddressDetails);

                this.billto = this.accountsaddressDetails.filter(item => item.Address_Type__c === 'Bill_to');
                console.log('OUTPUT : --this.billto--', this.billto);

                this.billtoOptions = this.billto.map(item => ({ label: item.Customer_Code__c, value: item.Customer_Code__c }));
                console.log('OUTPUT : --this.billtoOptions--', this.billtoOptions);

                this.shipTo = this.accountsaddressDetails.filter(item =>
                    item.Address_Type__c === 'Ship_to' ||
                    (item.Address_Type__c === 'Bill_to' && item.Ship_To__c === true)
                );


                this.shipToOptions = this.shipTo.map(item => ({ label: item.Customer_Code__c, value: item.Customer_Code__c }));
                console.log('OUTPUT : --this.shipToOptions--', this.shipToOptions);

            } else if (result.error) {
                console.error('Error fetching products:', result.error.body.message);
            }
        }).catch(error => {
            console.error(error);
        });
    }

    handleShiptoChange(event) {
        this.selectedshipto = event.detail.value;
        console.log('OUTPUT :-- this.selectedshipto--- ', this.selectedshipto);
        const filtereshipto = this.shipTo.find(item => item.Customer_Code__c === this.selectedshipto);
        console.log('OUTPUT :--filtereshipto-- ', filtereshipto);
        this.shippingAddress = filtereshipto.Street__c + ',' +
            filtereshipto.City__c + '\n' +
            filtereshipto.State__c + ' ' +
            filtereshipto.Country__c + '\n' +
            filtereshipto.Pincode__c;

        this.shippingObj = {
            accountId: filtereshipto.Account__c,
            addressId: filtereshipto.Id,
            street: filtereshipto.Street__c,
            city: filtereshipto.City__c,
            postalCode: filtereshipto.Pincode__c,
            stateCode: filtereshipto.State__c,
            countryCode: filtereshipto.Country__c,
            customerCode: filtereshipto.Customer_Code__c,
            addressType: filtereshipto.Address_Type__c
        };
        console.log('OUTPUT :--this.shippingAddress-- ', this.shippingAddress);
        console.log('OUTPUT :--this.shippingObj-- ', this.shippingObj);
    }

    handleBilltoChange(event) {
        this.selectedbillto = event.detail.value;
        console.log('OUTPUT :--selectedbillto-- ', this.selectedbillto);

        const filteredbillto = this.billto.find(item => item.Customer_Code__c === this.selectedbillto);
        console.log('OUTPUT :--filteredbillto-- ', filteredbillto);

        this.billingAddress = filteredbillto.Street__c + ',' +
            filteredbillto.City__c + '\n' +
            filteredbillto.State__c + ' ' +
            filteredbillto.Country__c + '\n' +
            filteredbillto.Pincode__c;

        this.billingObj = {
            accountId: filteredbillto.Account__c,
            addressId: filteredbillto.Id,
            street: filteredbillto.Street__c,
            city: filteredbillto.City__c,
            postalCode: filteredbillto.Pincode__c,
            stateCode: filteredbillto.State__c,
            countryCode: filteredbillto.Country__c,
            customerCode: filteredbillto.Customer_Code__c,
            addressType: filteredbillto.Address_Type__c
        };
        console.log('OUTPUT :--this.billingAddress-- ', this.billingAddress);
        console.log('OUTPUT :--this.billingObj-- ', this.billingObj);

    }

    @wire(getAllProducts)
    allProducts(result) {
        if (result.data) {
            this.fullProductList = result.data;
            this.productOptions = result.data.map(item => ({
                label: item.Product2?.Name,
                value: item.Id
            }));
            this.selectedRows = [this.createEmptyRow()];
        } else if (result.error) {
            console.error('Error fetching products:', result.error.body.message);
        }
    }

    createEmptyRow() {
        return {
            rowId: this.rowIdCounter++,
            selectedProductId: '',
            quantity: 1,
            pallets: 0,
            wp: 0,
            price: 0,
            total: 0,
            product2Id: '',
            palletFactor: 1
        };
    }

    handleAddRow() {
        this.selectedRows = [...this.selectedRows, this.createEmptyRow()];
    }

    getRelatedProducts(recordId) {
        getRelatedProducts({ recordId: recordId }).then(result => {
            this.productIds = new Set();
            if (result[0].Products__r != null) {
                result[0].Products__r.forEach(element => {
                    this.productIds.add(element.Id);
                });
            }
        });
    }

    async handleProductChange(event) {
        const rowId = parseInt(event.target.dataset.rowid, 10);
        const selectedProductId = event.detail.value;

        const product = this.fullProductList.find(item => item.Id === selectedProductId);
        if (!product) return;

        const row = this.selectedRows.find(r => r.rowId === rowId);
        if (!row) return;

        row.selectedProductId = selectedProductId;
        await this.updateAllProductPrices();
    }

    async handleQuantityChange(event) {
        const rowId = parseInt(event.target.dataset.rowid, 10);
        const quantity = parseFloat(event.target.value);
        const selectedProductId = event.target.dataset.seletedid;

        const row = this.selectedRows.find(r => r.rowId === rowId);
        if (!row) return;

        row.quantity = quantity;
        await this.updateAllProductPrices();
    }
    /**
    * Updates product prices based on quantity, pallets, and pricing conditions
    * This method calculates pallet factors, applies multiple pricing conditions, and updates totals
    */
    async updateAllProductPrices() {

        // Step 1: Calculate pallet factors and pallets for each selected row
        for (const row of this.selectedRows) {
            if (row.selectedProductId) {
                const product = this.fullProductList.find(item => item.Id === row.selectedProductId);
                if (product) {
                    // Get pallet factor from product, default to 1 if not available
                    const palletFactor = product.Product2?.Pallet_Factor__c || 1;
                    row.palletFactor = palletFactor;
                    // Calculate pallets based on quantity divided by pallet factor
                    row.pallets = parseFloat((row.quantity / palletFactor).toFixed(2));
                }
            }
        }

        // Step 2: Calculate total pallets across all rows (needed for pricing conditions)
        const currentPalletsTotal = parseFloat(this.selectedRows.reduce((sum, row) => {
            return sum + (parseFloat(row.pallets) || 0);
        }, 0).toFixed(2));

        console.log('Total Pallets for Pricing:', currentPalletsTotal);

        // Step 3: Fetch pricing conditions for all selected products
        const pricingPromises = this.selectedRows
            .filter(row => row.selectedProductId)
            .map(async (row) => {
                const product = this.fullProductList.find(item => item.Id === row.selectedProductId);
                if (!product) return null;

                try {
                    const productUnit = product.Product2?.Product_Unit__c || 'Units';
                    const lineItemQuantity = row.quantity || 0;
                    const lineItemPallets = row.pallets || 0;

                    // Determine quantity for comparison based on product unit type
                    let quantityForComparison;
                    if (productUnit.toLowerCase() === 'units') {
                        quantityForComparison = lineItemQuantity;
                    } else if (productUnit.toLowerCase() === 'pallets') {
                        quantityForComparison = lineItemPallets;
                    } else {
                        quantityForComparison = lineItemQuantity; // Default to units
                    }

                    // Fetch ALL applicable pricing conditions from Apex
                    const conditions = await getAllPricingConditions({
                        recordId: product.Product2Id,
                        pallets: currentPalletsTotal,
                        quantity: quantityForComparison
                    });

                    return { row, product, conditions: conditions || [], productUnit };
                } catch (error) {
                    console.error('Error fetching pricing conditions:', error.message);
                    return { row, product, conditions: [], productUnit: null };
                }
            });

        const pricingResults = await Promise.all(pricingPromises);

        // Step 4: Apply pricing conditions and calculate final prices
        for (const result of pricingResults) {
            if (!result) continue;

            const { row, product, conditions, productUnit } = result;
            const quantity = row.quantity || 0;
            let basePrice = product.UnitPrice; // Start with product's base price
            const wp = product.Product2?.Wp__c || 0; // Weight/packaging factor
            const productFamily = product.Product2?.Family || '';

            // Find the best applicable condition
            let appliedCondition = null;
            let bestDiscount = 0;

            for (const condition of conditions) {
                // Validate date range
                const today = new Date();
                const validFrom = new Date(condition.Valid_From__c);
                const validTo = new Date(condition.Valid_To__c);
                const isDateValid = today >= validFrom && today <= validTo;

                if (!isDateValid) {
                    // console.log(`Condition ${condition.Name} - Date invalid`);
                    continue;
                }

                // Check if condition matches product unit requirements
                let conditionMatches = false;

                // Calculate common matching conditions
                const totalPalletMatch = (condition.Total_Order_Pallet_From__c <= currentPalletsTotal &&
                    condition.Total_Order_Pallet_To__c >= currentPalletsTotal);

                // console.log(`Evaluating condition: ${condition.Name} for product: ${product.Product2?.Name}`);
                // console.log(`Product Unit: ${productUnit}, Total Pallets: ${currentPalletsTotal}, Line Quantity: ${quantity}, Line Pallets: ${row.pallets}`);
                // console.log(`Condition - Pallet Range: ${condition.Total_Order_Pallet_From__c} - ${condition.Total_Order_Pallet_To__c}`);
                // console.log(`Condition - Quantity Range: ${condition.Product_Quantity_From__c} - ${condition.Product_Quantity_To__c}`);

                // Handle Product Unit = 'units'
                if (productUnit && productUnit.toLowerCase() === 'units') {
                    // console.log('Processing Units-based pricing');

                    // Check if this is a quantity-specific condition
                    if (condition.Product_Quantity_From__c != null && condition.Product_Quantity_To__c != null) {
                        const quantityMatch = (condition.Product_Quantity_From__c <= quantity &&
                            condition.Product_Quantity_To__c >= quantity);

                        if (totalPalletMatch && quantityMatch) {
                            conditionMatches = true;
                            //  console.log('Matched: Units + Quantity condition');
                        }
                    } else {
                        // Pallet-only condition for units-based products
                        if (totalPalletMatch) {
                            conditionMatches = true;
                            //  console.log('Matched: Units + Pallet-only condition');
                        }
                    }
                }
                // Handle Product Unit = 'pallets'  
                else if (productUnit && productUnit.toLowerCase() === 'pallets') {
                    //  console.log('Processing Pallets-based pricing');

                    // Check if this is a pallet quantity-specific condition
                    if (condition.Product_Quantity_From__c != null && condition.Product_Quantity_To__c != null) {
                        const linePalletMatch = (condition.Product_Quantity_From__c <= row.pallets &&
                            condition.Product_Quantity_To__c >= row.pallets);

                        if (totalPalletMatch && linePalletMatch) {
                            conditionMatches = true;
                            // console.log('Matched: Pallets + Line Pallet condition');
                        }
                    } else {
                        // Total pallet-only condition
                        if (totalPalletMatch) {
                            conditionMatches = true;
                            // console.log('Matched: Pallets + Total Pallet-only condition');
                        }
                    }
                }
                // Handle Product Unit is null or empty
                else if (!productUnit || productUnit.trim() === '') {
                    // console.log('Processing NULL Product Unit');

                    // Only apply pallet-only conditions for null product units
                    if (totalPalletMatch && (condition.Product_Quantity_From__c == null && condition.Product_Quantity_To__c == null)) {
                        conditionMatches = true;
                        // console.log('Matched: NULL Product Unit + Pallet-only condition');
                    }
                }

                // Calculate discount value for comparison
                if (conditionMatches) {
                    const discountType = condition.Discount_Type__c;
                    const discountValue = parseFloat(condition.Discount_Value__c) || 0;
                    let calculatedDiscount = 0;

                    if (discountType === '%') {
                        calculatedDiscount = basePrice * (discountValue / 100);
                    } else if (discountType === 'Rs. / Wp') {
                        calculatedDiscount = discountValue;
                    } else if (discountType === 'Flat') {
                        calculatedDiscount = basePrice - discountValue; // Flat price means this much discount
                    }

                    // Use the condition with the highest discount
                    if (calculatedDiscount > bestDiscount) {
                        bestDiscount = calculatedDiscount;
                        appliedCondition = condition;
                    }

                    //  console.log(`Condition matches! Type: ${discountType}, Value: ${discountValue}, Calculated Discount: ${calculatedDiscount}`);
                }
            }

            // Apply the best condition found
            if (appliedCondition) {
                const discountType = appliedCondition.Discount_Type__c;
                const discountValue = parseFloat(appliedCondition.Discount_Value__c) || 0;

                console.log(`Applying BEST condition: ${appliedCondition.Name} - ${discountType} discount of ${discountValue} to ${product.Product2?.Name}`);

                // Apply discount based on type
                if (discountType === '%') {
                    basePrice -= basePrice * (discountValue / 100); // Percentage discount
                } else if (discountType === 'Rs. / Wp') {
                    basePrice = basePrice - discountValue; // Fixed amount per Wp
                } else if (discountType === 'Flat') {
                    basePrice = discountValue; // Fixed price override
                }

                // Store applied condition info for debugging
                row.appliedCondition = appliedCondition.Name;
                row.appliedDiscount = discountValue;
                row.appliedDiscountType = discountType;
            } else {
                console.log(`No applicable conditions found for ${product.Product2?.Name}`);
                row.appliedCondition = 'None';
            }

            // Update row with calculated values
            row.Wp = wp;
            row.price = basePrice.toFixed(2);
            row.productUnit = productUnit;
            row.productFamily = productFamily;

            // Calculate total based on product family
            if (productFamily === 'Inverter') {
                console.log('productFamily: ' + productFamily);
                row.total = (quantity * basePrice).toFixed(2);
            } else {
                console.log('productFamily: ' + productFamily);
                row.total = (quantity * wp * basePrice).toFixed(2);
            }

            // Final total calculation
            row.product2Id = product.Product2Id;
        }

        // Step 5: Update overall totals and refresh UI
        this.updateTotals();
        this.selectedRows = [...this.selectedRows]; // Force UI update with new array reference
    }
    handleDeleteRow(event) {
        const rowid = event.target.dataset.id;
        this.selectedRows = this.selectedRows.filter(row => row.rowId != rowid);
        this.updateTotals();

        const toastEvent = new ShowToastEvent({
            title: 'Product Delete',
            message: 'Product deleted successfully',
            variant: 'success',
            mode: 'dismissable'
        });
        this.dispatchEvent(toastEvent);
    }

    get wpTotal() {
        return this.selectedRows.reduce((sum, record) => {
            const quantity = Number(record.quantity) || 0;
            const wp = Number(record.Wp) || 0;
            return sum + (quantity * wp);
        }, 0);
    }

    get MwpTotal() {
        const wpTotal = this.wpTotal;
        const result = wpTotal / 1_000_000;
        return result.toFixed(2);
    }

    get palletsTotal() {
        return this.selectedRows.reduce((sum, record) => {
            const pallet = Number(record.pallets) || 0;
            return sum + pallet;
        }, 0);
    }

    get QuantityTotal() {
        return this.selectedRows.reduce((sum, record) => {
            const quantity = Number(record.quantity) || 0;
            return sum + quantity;
        }, 0);
    }

    get grandTotalp() {
        return this.selectedRows.reduce((sum, record) => {
            const amount = Number(record.total) || 0;
            return sum + amount;
        }, 0);
    }

    updateTotals() {
        const total = parseFloat(this.grandTotalp);
        this.tdsAmount = parseFloat((total * 0.001).toFixed(2));
        this.gstAmount = parseFloat((total * 0.05).toFixed(2));
        this.netPayable = parseFloat((total - this.tdsAmount).toFixed(2));
        this.finalPayable = parseFloat((this.netPayable + this.gstAmount).toFixed(2));

        this.formattedPallets = this.palletsTotal.toLocaleString('en-IN');
        this.formattedQuantity = this.QuantityTotal.toLocaleString('en-IN');
        this.formattedwptotal = this.wpTotal.toLocaleString('en-IN');
        this.formattedMWptotal = this.MwpTotal.toLocaleString('en-IN');
        this.formattedTotalAmount = this.grandTotalp.toLocaleString('en-IN');
        this.formattedTdsAmount = this.tdsAmount.toLocaleString('en-IN');
        this.formattedGstAmount = this.gstAmount.toLocaleString('en-IN');
        this.formattedGrandTotal = this.netPayable.toLocaleString('en-IN');
        this.formattedGrandTotalAmount = this.finalPayable.toLocaleString('en-IN');
    }

    // handleFileUpload(event) {
    //     const file = event.target.files[0];
    //     if (file) {
    //         this.uploadedFileName = file.name;
    //         const reader = new FileReader();
    //         reader.onload = () => {
    //             const base64 = reader.result.split(',')[1];
    //             this.fileBase64 = base64;
    //         };
    //         reader.readAsDataURL(file);
    //     }
    // }


    handleFileUpload(event) {
        const file = event.target.files[0]; // ✅ Declare the variable
        this.uploadedFile = file;
        if (file) {
            console.log('File selected:', file.name);
            this.uploadedFileName = file.name;

            const reader = new FileReader();
            reader.onload = () => {
                console.log('FileReader result:', reader.result);

                const base64 = reader.result.split(',')[1];
                console.log('Extracted Base64 content:', base64);

                this.fileBase64 = base64;
            };
            reader.onerror = (error) => {
                console.error('Error reading file:', error);
            };

            reader.readAsDataURL(file);
            console.log('Started reading file as data URL...');
        } else {
            console.warn('No file selected.');
        }
    }


    connectedCallback() {
        this.handleAccounts();
        // userCounts({ recordId: this.userId })
        //     .then(result => {
        //         if (result && result.length > 0) {
        //             this.accounts = result;
        //             this.acc = result[0];
        //         } else {
        //             console.log('No accounts found for the logged-in user.');
        //         }
        //     })
        //     .catch(error => {
        //         this.error = error;
        //         console.error('Error fetching accounts:', error);
        //     });
        getAccountForUser({ recordId: this.userId })
            .then(result => {
                console.log('OUTPUT :---result--- ', result);
                if (result) {
                    // this.accounts = result;
                    this.acc = result;
                    console.log('OUTPUT :---this.acc--- ', this.acc);
                } else {
                    console.log('No accounts found for the logged-in user.');
                }
            })
            .catch(error => {
                this.error = error;
                console.error('Error fetching accounts:', error);
            });

    }

    // Optional computed getter (if using getters in template)
    get gstNumber() {
        return this.acc?.Customer_GST_Number__c || '';
    }

    get accountName() {
        return this.acc?.Name || '';
    }
    get accountId() {
        return this.acc?.Id || '';
    }

    @wire(getNewLeadsCountByUser, { userId: '$userId' })
    wiredLeadCounts({ error, data }) {
        if (data) {
            this.LeadCounts = data;
            this.dataload = true;
        } else if (error) {
            this.error = error;
            console.error('Error fetching order counts:', error);
        }
    }

    @wire(countAndFetchOrdersByUser, { userId: '$userId' })
    wiredOrderData({ error, data }) {
        if (data) {
            this.orderCounts = {
                Closed: data.Closed,
                InTransit: data.InTransit
            };

            this.closedOrders = data.ClosedOrders.map((order, i) => ({
                ...order,
                index: i + 1
            }));

            this.inTransitOrders = data.InTransitOrders.map((order, i) => ({
                ...order,
                index: i + 1
            }));
            this.dataload = true;
        } else if (error) {
            this.error = error;
            console.error('Error fetching order data:', error);
        }
    }

    orderfunction() {
        this.model = true;
        this.ismodalopen = true;
    }

    closeModal() {
        this.ismodalopen = false;
    }



    // async handleSubmit() {
    //     let hasWarning = false;




    //     const selectedProductIds = this.selectedRows
    //         .filter(row => row.product2Id)
    //         .map(row => row.product2Id);

    //     if (selectedProductIds.length < 1) return;



    //     for (let i = 0; i < selectedProductIds.length; i++) {
    //         const product1Id = selectedProductIds[i];
    //         const today = new Date();
    //         const formattedDate = today.toISOString().split('T')[0];

    //         try {



    //             const schemes = await checkPricingSchemes({
    //                 product1Id: product1Id,
    //                 orderDate: formattedDate
    //             });

    //             for (const scheme of schemes) {
    //                 if (scheme.product1Id === product1Id) {
    //                     const product2Id = scheme.product2Id;
    //                     const hasProduct2 = selectedProductIds.includes(product2Id);
    //                     const row1 = this.selectedRows.find(r => r.product2Id === product1Id);
    //                     const row2 = this.selectedRows.find(r => r.product2Id === product2Id);

    //                     if (!hasProduct2 || !row2) {
    //                         this.showWarning(
    //                             `Based on condition type "${scheme.conditionType}", ` +
    //                             `you must also purchase Product ${scheme.proName} ` +
    //                             `with quantity based on condition value ${scheme.conditionValue}`
    //                         );
    //                         hasWarning = true;
    //                     } else {
    //                         const qty1 = parseFloat(row1.quantity || 0);
    //                         const qty2 = parseFloat(row2.quantity || 0);
    //                         const requiredQty = qty1 * (parseFloat(scheme.conditionValue || 0) / 100);

    //                         if (qty2 < requiredQty) {
    //                             this.showWarning(
    //                                 `You must select at least ${scheme.conditionValue}% (${requiredQty}) quantity of Product ${scheme.proName} ` +
    //                                 `as it is dependent on ${qty1} quantity of main product. Currently selected: ${qty2}`
    //                             );
    //                             hasWarning = true;
    //                         }
    //                     }
    //                 }
    //             }

    //          if (!this.selectedFiles || this.selectedFiles.length === 0) {
    //     this.showWarning('You have to upload at least one attachment before submitting');
    //     console.warn('Order creation skipped: Attachment is required but missing.');
    //     return;
    // }

    //         } 

    //         catch (error) {
    //             console.error('Error checking pricing schemes:', error);
    //         }
    //     }

    //     if (hasWarning) {
    //         console.warn('Order creation skipped due to pricing scheme warning.');
    //         return;
    //     }

    //     this.createOrder();
    // }


    async handleSubmit() {

        const selectedProductIds = this.selectedRows
            .filter(row => row.product2Id)
            .map(row => row.product2Id);

        if (selectedProductIds.length < 1) return;

        let hasWarning = false;

        for (let i = 0; i < selectedProductIds.length; i++) {
            const product1Id = selectedProductIds[i];
            const today = new Date();
            const formattedDate = today.toISOString().split('T')[0];

            try {
                const schemes = await checkPricingSchemes({
                    product1Id: product1Id,
                    orderDate: formattedDate
                });

                for (const scheme of schemes) {
                    if (scheme.product1Id === product1Id) {
                        const product2Id = scheme.product2Id;
                        const hasProduct2 = selectedProductIds.includes(product2Id);
                        const row1 = this.selectedRows.find(r => r.product2Id === product1Id);
                        const row2 = this.selectedRows.find(r => r.product2Id === product2Id);

                        if (!hasProduct2 || !row2) {
                            this.showWarning(
                                `Based on condition type "${scheme.conditionType}", ` +
                                `you must also purchase Product ${scheme.proName} ` +
                                `with quantity based on condition value ${scheme.conditionValue}`
                            );
                            hasWarning = true;
                        } else {
                            const qty1 = parseFloat(row1.quantity || 0);
                            const qty2 = parseFloat(row2.quantity || 0);
                            const requiredQty = qty1 * (parseFloat(scheme.conditionValue || 0) / 100);

                            if (qty2 < requiredQty) {
                                this.showWarning(
                                    `You must select at least ${scheme.conditionValue}% (${requiredQty}) quantity of Product ${scheme.proName} ` +
                                    `as it is dependent on ${qty1} quantity of main product. Currently selected: ${qty2}`
                                );
                                hasWarning = true;
                            }
                        }
                    }
                }
                if (!this.uploadedFile) {
                    this.showWarning('Please upload an attachment before submitting the order.');
                    return;
                }

            } catch (error) {
                console.error('Error checking pricing schemes:', error);
            }
        }

        if (hasWarning) {
            console.warn('Order creation skipped due to pricing scheme warning.');
            return;
        }

        this.createOrder();
    }

    createOrder() {
        console.log('OUTPUT :--his.accountId-- ', this.accountId);
        let orderObj = {
            'PoNumber': this.ponum,
            'PoDate': this.today,
            'billingAddress': this.billingObj,
            'shippingAddress': this.shippingObj,
            'orderProducts': this.selectedRows,
            'account': this.accountId,
            'fileName': this.uploadedFileName,
            'fileContent': this.fileBase64,
            'grandTotal': parseFloat(this.finalPayable),
            'Mwp': parseFloat(this.MwpTotal),
            'TotalQuantity': parseFloat(this.QuantityTotal),
            'Totalwp': parseFloat(this.wpTotal)
        };

        createOrderFromJSON({ orderJson: JSON.stringify(orderObj) })
            .then(result => {
                const toastEvent = new ShowToastEvent({
                    title: 'Order Created',
                    message: 'Order Created Successfully!',
                    variant: 'Success',
                    mode: 'dismissable'
                });
                this.dispatchEvent(toastEvent);
                window.location.reload();
            })
            .catch(error => {
                const toastEvent = new ShowToastEvent({
                    title: 'Order Not Created',
                    message: 'Error',
                    variant: 'Error',
                    mode: 'dismissable'
                });
                this.dispatchEvent(toastEvent);
                console.error('Error creating order: ', error);
                console.error('Error creating order: ', error?.body?.message || JSON.stringify(error));

            });
    }

    showWarning(message) {
        const toastEvent = new ShowToastEvent({
            title: 'Warning',
            message: message,
            variant: 'warning',
            mode: 'dismissable'
        });
        this.dispatchEvent(toastEvent);
    }
}