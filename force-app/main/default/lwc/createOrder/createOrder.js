import { LightningElement, track, wire } from 'lwc';
import userCounts from '@salesforce/apex/HomeOrderControllers.userCounts'
import countAndFetchOrdersByUser from '@salesforce/apex/HomeOrderControllers.countAndFetchOrdersByUser';
import checkPricingSchemes from '@salesforce/apex/HomeOrderControllers.checkPricingSchemes';
import getAllProducts from '@salesforce/apex/HomeOrderControllers.getAllProducts';
import getNewLeadsCountByUser from '@salesforce/apex/HomeOrderControllers.getNewLeadsCountByUser';
import getMetaData from '@salesforce/apex/HomeOrderControllers.getMetaData';
import getAccountAddressDetails from '@salesforce/apex/HomeOrderControllers.getAccountAddressDetails';
import USER_Id from '@salesforce/user/Id';
import getpricingiCondition from '@salesforce/apex/HomeOrderControllers.getpricingiCondition'
import getRelatedProducts from '@salesforce/apex/HomeOrderControllers.getRelatedProducts'
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import logoPremier from '@salesforce/resourceUrl/logoPremier'
import createOrderFromJSON from '@salesforce/apex/HomeOrderControllers.createOrderFromJSON'



export default class CreateOrder extends LightningElement {

    logoPremier = logoPremier

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
    handlePoNumChange(event) {
        this.ponum = event.target.value
    }


    getDate() {
        const todayDate = new Date();
        this.today = todayDate.toISOString().split('T')[0];
    }

    @wire(getMetaData)
    allMetarecords(result) {
        console.log('result', result);
        console.log('result', result.data);

        if (result.data) {
            this.metarecords = result.data;
            console.log('this.metarecords---->', this.metarecords);
            this.getDate()

        }
        else if (result.error) {
            console.error('Error fetching products:', result.error.body.message);
        }
    }
    @track billto = []
    @track shipTo = []
    @track selectedbillto;
    @track accountsaddressDetails = []
    @track selectedshipto;
    @track billtoOptions = []
    @track shipToOptions = []

    handleAccounts() {
        getAccountAddressDetails({ recordId: this.userId }).then(result => {

            if (result) {
                console.log('==============result8888888888======================');
                console.log(result);
                console.log('====================================');
                this.accountsaddressDetails = result[0].Adresses__r != null ? result[0].Adresses__r : [];
                console.log('==============accountsaddressDetails======================');
                console.log(JSON.stringify(this.accountsaddressDetails));
                console.log('====================================');
                console.log('this.accounts---->', this.accounts);
                this.billto = this.accountsaddressDetails.filter(item => item.Address_Type__c === 'Bill_to')
                console.log('==================billto==================');
                console.log(JSON.stringify(this.billto));
                console.log('====================================');
                this.billtoOptions = this.billto.map(item => ({ label: item.Customer_Code__c, value: item.Customer_Code__c }));
                console.log('================billtoOptions====================');
                console.log(JSON.stringify(this.billtoOptions));
                console.log('====================================');
                this.shipTo = this.accountsaddressDetails.filter(item => item.Address_Type__c === 'Ship_to')
                this.shipToOptions = this.shipTo.map(item => ({ label: item.Customer_Code__c, value: item.Customer_Code__c }));
            }
            else if (result.error) {
                console.error('Error fetching products:', result.error.body.message);
            }
        }).catch(error => {
            console.log('====================================');
            console.log(error);
            console.log('====================================');
        })
    }
    @track billingAddress
    @track shippingAddress
    @track shippingObj
    @track billingObj
    handleShiptoChange(event) {
        this.selectedshipto = event.detail.value;
        const filtereshipto = this.shipTo.find(item => item.Customer_Code__c === this.selectedshipto)
        console.log('===============filteredbillto=====================');
        console.log(filtereshipto);
        console.log('====================================');
        this.shippingAddress = filtereshipto.Address__Street__s + ',' +
            filtereshipto.Address__City__s + '\n' +
            filtereshipto.Address__StateCode__s + ' ' +
            filtereshipto.Address__CountryCode__s + '\n' +
            filtereshipto.Address__PostalCode__s;
        this.shippingObj = {
            accountId: filtereshipto.Account__c,
            addressId: filtereshipto.Id,
            city: filtereshipto.Address__City__s,
            postalCode: filtereshipto.Address__PostalCode__s,
            stateCode: filtereshipto.Address__StateCode__s,
            countryCode: filtereshipto.Address__CountryCode__s,
            customerCode: filtereshipto.Customer_Code__c,
            addressType: filtereshipto.Address_Type__c
        }
    }
    handleBilltoChange(event) {
        this.selectedbillto = event.detail.value;

        const filteredbillto = this.billto.find(item => item.Customer_Code__c === this.selectedbillto)
        console.log('===============filteredbillto=====================');
        console.log(filteredbillto);
        console.log('====================================');
        this.billingAddress = filteredbillto.Address__Street__s + ',' +
            filteredbillto.Address__City__s + '\n' +
            filteredbillto.Address__StateCode__s + ' ' +
            filteredbillto.Address__CountryCode__s + '\n' +
            filteredbillto.Address__PostalCode__s;
        this.billingObj = {
            accountId: filteredbillto.Account__c,
            addressId: filteredbillto.Id,
            city: filteredbillto.Address__City__s,
            postalCode: filteredbillto.Address__PostalCode__s,
            stateCode: filteredbillto.Address__StateCode__s,
            countryCode: filteredbillto.Address__CountryCode__s,
            customerCode: filteredbillto.Customer_Code__c,
            addressType: filteredbillto.Address_Type__c
        }
    }
    @wire(getAllProducts)
    allProducts(result) {
        if (result.data) {
            this.fullProductList = result.data;
            console.log('================debuggggg====================');
            console.log(JSON.stringify(this.fullProductList, null, 2));
            console.log('====================================');

            console.log('====================================');
            this.productOptions = result.data.map(item => ({
                label: item.Product2?.Name,
                value: item.Id
            }));
            // Map the products to options
            // this.productOptions = result.data.map(item => ({
            //     label: item.productName,  // Correct field name for product name
            //     value: item.productId
            // }));
            console.log('productOptions--->', JSON.stringify(this.productOptions));

            this.selectedRows = [this.createEmptyRow()];
            console.log('OUTPUT : ----- this.selectedRows', this.selectedRows);
        } else if (result.error) {
            console.error('Error fetching products:', result.error.body.message);
        }
    }

    createEmptyRow() {
        return {
            rowId: this.rowIdCounter++,
            selectedProductId: '',
            quantity: 1,
            wp:0,
            price: 0,
            total: 0,
            product2Id: ''
        };
    }

    handleAddRow() {
        this.selectedRows = [...this.selectedRows, this.createEmptyRow()];
        console.log('OUTPUT : ----selectedRows---handleAddRow-->', selectedRows);
    }
    @track productIds
    getRelatedProducts(recordId) {
        getRelatedProducts({ recordId: recordId }).then(result => {
            console.log('OUTPUT :result--------> getrelatedProducts---> ', result);
            this.productIds = new Set();
            console.log('============related========================');
            console.log(JSON.stringify(result, null, 2));

            console.log('====================================');
            if (result[0].Products__r != null) {
                result[0].Products__r.forEach(element => {
                    this.productIds.add(element.Id)
                });
            }
        })
        console.log('=================productIds===================');
        console.log(this.productIds);
        console.log('====================================');
    }
    handleProductChange(event) {
        const rowId = parseInt(event.target.dataset.rowid, 10);
        console.log('OUTPUT : <-------handleProductChangerowId-------------------->>>>>>>>>>', rowId);
        const selectedProductId = event.detail.value;
        console.log('OUTPUT : <-------selectedProductId-------------------->>>>>>>>>>', selectedProductId);

        const product = this.fullProductList.find(item => item.Id === selectedProductId)
        console.log('===============selectedProductId=====================');
        console.log(selectedProductId, 'product' + product.Product2Id);
        console.log('====================================');
        // this.getRelatedProducts(product.Product2Id)
        getpricingiCondition({ recordId: product.Product2Id }).then(result => {
            console.log('===================result****************=================');
            console.log(result);
            console.log('====================================');
            if (result) {
                let wp = parseFloat(result.WpFormula__c) != null ? parseFloat(result.WpFormula__c) : 0;
                let palletMin = parseFloat(result.Pallet_Min__c) != null ? parseFloat(result.Pallet_Min__c) : 0;
                let palletMax = parseFloat(result.Pallet_Max__c) != null ? parseFloat(result.Pallet_Max__c) : 0;
                let validFrom = new Date(result.Valid_From__c);
                let validTo = new Date(result.Valid_To__c);
                let discountType = result.Discount_Type__c;
                let discountValue = parseFloat(result.Discount_Value__c);

                const today = new Date();

                // Check Wp is between Pallet Min and Max
                const isWpInRange = wp >= palletMin && wp <= palletMax;
                console.log('=========isWpInRange===========================', wp);
                console.log(isWpInRange);
                console.log('====================================');
                // Check current date is between Valid From and Valid To
                const isDateValid = today >= validFrom && today <= validTo;
                console.log('============isDateValid========================');
                console.log(isDateValid);
                console.log('====================================');
                const row = this.selectedRows.find(r => r.rowId === rowId);
                console.log('OUTPUT :----row----this.selectedRow-----> ', row);
                if (row) {
                    row.selectedProductId = selectedProductId;

                    const product = this.fullProductList.find(p => p.Id === selectedProductId);
                    console.log('OUTPUT : ----product-----',product);
                    if (product) {
                        let basePrice = product.UnitPrice;
                        let wp = product.Product2.Wp__c;
                        console.log('==========basePrice==========================discountValue', discountValue);
                        console.log(basePrice);
                        console.log('====================================');
                        console.log('OUTPUT --------WP------------: ',wp);
                        // Apply discount if both conditions pass
                        if (isWpInRange && isDateValid) {
                            if (discountType === '%') {
                                basePrice = basePrice - (basePrice * (discountValue) / 100);
                            } else if (discountType === 'Rs. / Wp') {
                                basePrice = basePrice - parseFloat(discountValue);
                            }
                        }

                        row.Wp = wp;
                        row.price = basePrice;
                        row.total = row.quantity * basePrice;
                        row.product2Id = product.Product2Id;
                        console.log('=============basePrice_____=======================');
                        console.log(basePrice);
                        console.log('====================================');
                        this.updateTotals();
                    }
                }
            }
        }).catch(error => {
            console.error('Error fetching pricing conditions:', error);
            const row = this.selectedRows.find(r => r.rowId === rowId);
            console.log('OUTPUT :----->row-------->catch--------> ', row);
            if (row) {
                row.selectedProductId = selectedProductId;

                const products = this.fullProductList.find(p => p.Id === selectedProductId);
                if (products) {
                    let basePrice = product.UnitPrice;
                    let wp = product.Product2.Wp__c;

                    // Apply discount if both conditions pass

                    row.Wp = wp;
                    row.price = basePrice;
                    row.total = row.quantity * basePrice;
                    row.product2Id = product.Product2Id;
                    console.log('=============basePrice_____=======================');
                    console.log(basePrice);
                    console.log('====================================');
                    this.updateTotals();
                }
            }
        });
    }
    handleDeleteRow(event) {
        const rowid = event.target.dataset.id
        console.log('=========rowid===========================');
        console.log(rowid);
        console.log('====================================');
        this.selectedRows = this.selectedRows.filter(row => row.rowId != rowid)
        console.log('=================this.selectedRows===================');
        console.log(JSON.stringify(this.selectedRows, null, 2));
        console.log('====================================');
        const toastEvent = new ShowToastEvent({
            title: 'Product Delete',
            message: 'Product deleted successfully',
            variant: 'success',
            mode: 'dismissable'
        });
        this.dispatchEvent(toastEvent);

    }

    handleQuantityChange(event) {
        const rowId = parseInt(event.target.dataset.rowid, 10);
        const quantity = parseInt(event.target.value, 10) || 1;
        console.log('=============quantity=======================');
        console.log(quantity);
        console.log('====================================');
        const row = this.selectedRows.find(r => r.rowId === rowId);
        console.log('OUTPUT : selected Row--------------->------', row);
        if (row) {
            row.quantity = quantity;
            row.total = row.quantity * row.price;
            this.updateTotals()
        }
    }

    get wpTotal(){
        return this.selectedRows.reduce((sum,record)=>{
            const whatp =Number(record.Wp) || 0;
            return sum + whatp;
        }, 0);
    }
    get MwpTotal(){   
    const quantityTotal = this.QuantityTotal;
    const wpTotal = this.wpTotal;
    const result = (quantityTotal * wpTotal) / 1_000_000;
    return result.toFixed(2); // Optional: formats to 2 decimal places
}


    get QuantityTotal(){
        return this.selectedRows.reduce((sum ,record)=>{
            const quantity = Number(record.quantity) || 0;
            return sum + quantity;
        }, 0);
    }

    // eslint-disable-next-line no-dupe-class-members
    get grandTotal() {
        return this.selectedRows.reduce((sum, record) => {
            const amount = Number(record.total) || 0;
            return sum + amount;
        }, 0);
    }

    updateTotals() {
        let total = 0;
        this.selectedRows.forEach(row => {
            total += row.total || 0;
        });

        this.grandTotal = total;
        this.tdsAmount = +(total * 0.001).toFixed(2); // 0.1% TDS
        this.gstAmount = +(total * 0.12).toFixed(2);  // GST @ 12%
        this.netPayable = +(total - this.tdsAmount).toFixed(2);
        this.finalPayable = +(total - this.tdsAmount + this.gstAmount).toFixed(2);

    }

    handleFileUpload(event) {
        const file = event.target.files[0];
        if (file) {
            this.uploadedFileName = file.name;
            const reader = new FileReader();
            reader.onload = () => {
                const base64 = reader.result.split(',')[1];
                this.fileBase64 = base64;
            };
            reader.readAsDataURL(file);
        }
    }

    connectedCallback() {
        console.log('=============called=======================');
        console.log('called');
        console.log('====================================');
        this.handleAccounts()
        userCounts({ recordId: this.userId })
            .then(result => {
                if (result && result.length > 0) {
                    this.accounts = result;
                    console.log('==================this.accounts[0]==================');
                    console.log(result[0]);
                    console.log('====================================');
                    this.acc = result[0]
                    console.log('Accounts fetched:', JSON.stringify(this.accounts, null, 2));
                    console.log('Accounts fetched-------------------:', JSON.stringify(this.acc));
                } else {
                    console.log('No accounts found for the logged-in user.');
                }
            })
            .catch(error => {
                this.error = error;
                console.error('Error fetching accounts:', error);
            });
    }

    @wire(getNewLeadsCountByUser, { userId: '$userId' })
    wiredLeadCounts({ error, data }) {
        if (data) {
            console.log('data', data);

            this.LeadCounts = data;
            console.log('orderCounts', this.orderCounts);
        } else if (error) {
            this.error = error;
            console.error('Error fetching order counts:', error);
        }
    }

    /* @wire(countOrdersByUser, { userId: '$userId' })
     wiredOrderCounts({ error, data }) {
         if (data) {
             console.log('data',data);
             
             this.orderCounts = data;
             console.log('orderCounts',this.orderCounts);
         } else if (error) {
             this.error = error;
             console.error('Error fetching order counts:', error);
         }
     }*/


    @wire(countAndFetchOrdersByUser, { userId: '$userId' })
    wiredOrderData({ error, data }) {
        if (data) {
            console.log('data:', data);
            this.orderCounts = {
                Closed: data.Closed,
                InTransit: data.InTransit
            };
            // this.closedOrders = data.ClosedOrders;
            // console.log('this.closedOrders',this.closedOrders);

            // this.inTransitOrders = data.InTransitOrders;
            // console.log('this.inTransitOrders',this.inTransitOrders);
            // 👇 Add index manually starting from 1
            this.closedOrders = data.ClosedOrders.map((order, i) => ({
                ...order,
                index: i + 1
            }));

            this.inTransitOrders = data.InTransitOrders.map((order, i) => ({
                ...order,
                index: i + 1
            }));
        } else if (error) {
            this.error = error;
            console.error('Error fetching order data:', error);
        }
    }

    orderfunction() {
        this.model = true;
        // this.acc = false;
        this.ismodalopen = true;
    }
    closeModal() {
        this.ismodalopen = false;
    }


    orderWholeData = [];
    orderCounts = {
        total: 0
    };

    // @wire(orderMethod)
    // orderdate({ data, error }) {
    //     if (data) {
    //         this.orderWholeData = data;
    //         this.calculationOrder(data);
    //         console.log('orderLivedata ', JSON.stringify(data));
    //     } else if (error) {
    //         console.error('error', error.body.message);
    //     }
    // }

    // calculationOrder(orders) {
    //     let total = 0;
    //     orders.forEach(order => {
    //         total += order.total; 
    //     });

    //     this.orderCounts = {
    //         total
    //     };
    // }
    // calculateRequiredQuantities() {

    //     const product1Rows = this.selectedRows.filter(row => {
    //         return this.pricingSchemes.some(scheme => 
    //             scheme.product1Id === row.selectedProductId
    //         );
    //     });

    //     product1Rows.forEach(row => {
    //         const schemesForProduct = this.pricingSchemes.filter(
    //             scheme => scheme.product1Id === row.selectedProductId
    //         );

    //         schemesForProduct.forEach(scheme => {
    //             if (scheme.conditionType === '% of P1') {
    //                 const requiredQty = Math.ceil(
    //                     row.quantity * (scheme.conditionValue / 100)
    //                 );

    //                 // Check if Product 2 exists
    //                 const product2Row = this.selectedRows.find(
    //                     r => r.selectedProductId === scheme.product2Id
    //                 );

    //                 if (!product2Row) {
    //                     this.showWarning(
    //                         `You must add Product ${scheme.product2Id} with ` +
    //                         `minimum quantity ${requiredQty} (${scheme.conditionValue}% of Product 1)`
    //                     );
    //                 } else if (product2Row.quantity < requiredQty) {
    //                     this.showWarning(
    //                         `Quantity for Product ${scheme.product2Id} must be at least ` +
    //                         `${requiredQty} (${scheme.conditionValue}% of Product 1)`
    //                     );
    //                     // Auto-update the quantity to meet requirement
    //                     product2Row.quantity = requiredQty;
    //                     product2Row.total = product2Row.quantity * product2Row.price;
    //                     this.updateTotals();
    //                 }
    //             }
    //         });
    //     });
    // }
    // async handleProductChange(event) {
    //     const rowId = parseInt(event.target.dataset.rowid, 10);
    //     const selectedProductId = event.detail.value;

    //     const row = this.selectedRows.find(r => r.rowId === rowId);
    //     if (row) {
    //         row.selectedProductId = selectedProductId;
    //         const product = this.fullProductList.find(p => p.Id === selectedProductId);
    //         if (product) {
    //             row.price = product.UnitPrice;
    //             row.total = row.quantity * row.price;

    //             this.updateTotals();
    //         }

    //         // Check for pricing schemes when products are selected
    //         await this.handleSubmit();
    //     }
    // }

    async handleSubmit() {
        console.log('==============***************======================');
        console.log(JSON.stringify(this.selectedRows, null, 2));
        // this.ismodalopen = false;
        const selectedProductIds = this.selectedRows
            .filter(row => row.product2Id)
            .map(row => row.product2Id);

        console.log('OUTPUT : ---selectedProductIds----->', JSON.stringify(selectedProductIds));

        if (selectedProductIds.length < 1) return;

        let hasWarning = false;


        if (selectedProductIds.length != 0) {
            for (let i = 0; i < selectedProductIds.length; i++) {
                const product1Id = selectedProductIds[i];
                const today = new Date();
                const formattedDate = today.toISOString().split('T')[0];

                try {
                    const schemes = await checkPricingSchemes({
                        product1Id: product1Id,
                        //  product2Id: Array.from(this.productIds),
                          orderDate: formattedDate
                    });
                    console.log('OUTPUT : ------schemes----->', schemes);

                    for (const scheme of schemes) {
                        if (scheme.product1Id === product1Id) {
                            const hasProduct2 = selectedProductIds.includes(scheme.product2Id);
                            console.log('hasProduct2--> : ', hasProduct2);

                            if (!hasProduct2) {
                                this.showWarning(
                                    `Based on condition type "${scheme.conditionType}", ` +
                                    `you must also purchase Product ${scheme.proName} ` +
                                    `with quantity based on condition value ${scheme.conditionValue}`
                                );

                                hasWarning = true;
                            }
                        }
                    }
                } catch (error) {
                    console.error('Error checking pricing schemes:', error);
                }
            }
        }


        if (hasWarning) {
            console.warn(' Order creation skipped due to pricing scheme warning.');
            return;
        }

        console.log('No warnings, proceeding to create order...');
        this.createOrder();
    }

    createOrder() {
        let orderObj = {
            'PoNumber': this.ponum,
            'PoDate': this.today,
            'billingAddress': this.billingObj,
            'shippingAddress': this.shippingObj,
            'orderProducts': this.selectedRows,
            'account': this.accounts[0].account.Id,
            'fileName': this.uploadedFileName,
            'fileContent': this.fileBase64,
            'grandTotal': parseFloat(this.finalPayable),
            'Mwp':parseFloat(this.MwpTotal),
            'TotalQuantity':parseFloat(this.TotalQuantity),
            'Totalwp':parseFloat(this.wpTotal)

        }
        console.log('=================orderObj===================');
        console.log(orderObj);
        console.log('=================orderObj===================');
        console.log(JSON.stringify(orderObj, null, 2));
        console.log('====================================');
        createOrderFromJSON({ orderJson: JSON.stringify(orderObj) })
            .then(result => {
                const toastEvent = new ShowToastEvent({
                    title: 'Order Created',
                    message: 'Order Created Successfully!',
                    variant: 'Success',
                    mode: 'dismissable'
                });
                this.dispatchEvent(toastEvent);
                console.log('Order created with Id: ', result);
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
            });
    }

    showWarning(message) {

        const toastEvent = new ShowToastEvent({
            title: 'Product Combination Required',
            message: message,
            variant: 'warning',
            mode: 'dismissable'
        });
        this.dispatchEvent(toastEvent);
    }
}