import { LightningElement, wire, api, track } from 'lwc';
import getRawMaterialData from '@salesforce/apex/RawMaterialLogger.RawMaterial';
import userId from '@salesforce/user/Id';
import getUserProfileName from '@salesforce/apex/RawMaterialLogger.getUserProfileName';
import getAdminInputs from '@salesforce/apex/RawMaterialLogger.getAdminInputs';
import createVariables from '@salesforce/apex/RawMaterialLogger.createVariables';
import checkVariables from '@salesforce/apex/RawMaterialLogger.checkVariables';
export default class RawMaterialLogger extends LightningElement {
    @api recordId;
    currentUserId = userId;
    // Tracked properties for dropdowns
    @track countrySource = 'China';
    @track pricingType = 'Average Price';
    @track isEditable = false;
    costRows = [];
    @track totalInrWp = 0;
    @track totalCentWp = 0;
    @track storeVariableIds = [];

    // Dropdown options
    countryOptions = [
        { label: 'China', value: 'China' },
        { label: 'Malaysia', value: 'Malaysia' },
        { label: 'Vietnam', value: 'Vietnam' }
    ];

    pricingOptions = [
        { label: 'Average Price', value: 'Average Price' },
        { label: 'Low Price', value: 'Low Price' }
    ];

    // Track raw material data
    @track rawMaterialData = [];
    @track formattedData = [];
    @track allRawMaterialVariants = [];

    connectedCallback() {
        console.log('countrySource : ', this.countrySource);
        console.log('pricingType : ', this.pricingType);
        console.log('Logged-in User ID:', this.currentUserId);
        getUserProfileName({ userId: this.currentUserId })
            .then(profileName => {
                console.log('Retrieved Profile Name:', profileName);
                if (profileName == 'Key Accounts National Head') {
                    this.isEditable = true;
                }
            })
            .catch(error => {
                console.error('Error fetching user profile:', error);
                if (error.body && error.body.message) {
                    console.error('Error message:', error.body.message);
                } else {
                    console.error('Error:', error.message);
                }
            });

    }

    fetchAdminInputs() {
        getAdminInputs({ oppId: this.recordId })
            .then(data => {
                console.log('Admin data--> : ', data);
                console.log('cbitc--> : ', data.cbitc);
                console.log('totalInrWp--> : ', this.totalInrWp);
                console.log('data.warrantyInsurance--> : ', data.warrantyInsurance);
                console.log('data.rfidCostINR--> : ', data.rfidCostINR);
                console.log('data.moduleOverheadINR--> : ', data.moduleOverheadINR);
                const totalvalue = parseFloat(this.totalInrWp) || 0;
                console.log('addvalues--> : ', parseFloat(totalvalue + data.rfidCostINR + data.moduleOverheadINR));
                var moduleWarrantyInsuranceCostINR = (totalvalue + data.rfidCostINR + data.moduleOverheadINR) * (data.warrantyInsurance / 100);
                console.log('moduleWarrantyInsuranceCostINR--> : ', moduleWarrantyInsuranceCostINR);
                var moduleWarrantyInsuranceCostCent = ((moduleWarrantyInsuranceCostINR * 100) / data.rbi);
                var bGradeModuleLossINR = ((totalvalue + data.rfidCostINR + data.moduleOverheadINR + data.cellBOMINR + data.cellOverheadINR + data.cellFinanceINR + moduleWarrantyInsuranceCostINR) * (data.bgrademodulediscount / 100) * (data.bgrademoduleyield / 100));
                var bGradeModuleLossCent = ((bGradeModuleLossINR * 100) / data.rbi);
                moduleWarrantyInsuranceCostINR = Number(moduleWarrantyInsuranceCostINR.toFixed(2));
                bGradeModuleLossINR = Number(bGradeModuleLossINR.toFixed(2));
                moduleWarrantyInsuranceCostCent = moduleWarrantyInsuranceCostCent.toFixed(2);
                bGradeModuleLossCent = bGradeModuleLossCent.toFixed(2);
                const abgCostINR = Number((
                    (parseFloat(data.abgvalue) || 0) *
                    (parseFloat(data.abgpbgcost / 100) || 0) /
                    365 *
                    (parseFloat(data.abgvalidity) || 0) /
                    (parseFloat(data.projectcapacity) || 1) /
                    1000000
                ).toFixed(2));
                const abgCostCent = ((abgCostINR * 100) / data.rbi).toFixed(2);
                console.log('data.pbgvalue--> : ', data.pbgvalue);
                console.log('data.abgpbgcost--> : ', data.abgpbgcost);
                console.log('data.pbgvalidity--> : ', data.pbgvalidity);
                console.log('data.projectcapacity--> : ', data.projectcapacity);
                const pbgCostINR = Number((
                    (parseFloat(data.pbgvalue) || 0) *
                    (parseFloat(data.abgpbgcost / 100) || 0) /
                    365 *
                    (parseFloat(data.pbgvalidity) || 0) /
                    (parseFloat(data.projectcapacity) || 1) /
                    1000000
                ).toFixed(2));

                const pbgCostCent = ((pbgCostINR * 100) / data.rbi).toFixed(2);
                console.log('data.insurancepremiumcost--> : ', data.insurancepremiumcost);
                var transitinsurancecostINR = parseFloat(totalvalue + data.rfidCostINR + data.moduleOverheadINR + data.moduleFinanceINR + data.cellBOMINR + data.cellOverheadINR + data.cellFinanceINR + moduleWarrantyInsuranceCostINR + bGradeModuleLossINR + abgCostINR + pbgCostINR + data.outboundlogisticsINR + data.exportfreightchargesINR) * (data.insurancepremiumcost / 100);
                var transitinsurancecostCent = (transitinsurancecostINR * 100 / data.rbi);
                transitinsurancecostINR = Number(transitinsurancecostINR.toFixed(2));
                console.log('transitinsurancecostINR--> : ', transitinsurancecostINR);
                transitinsurancecostCent = transitinsurancecostCent.toFixed(2);
                console.log('data.paymentterm--> : ', data.paymentterm);
                console.log('data.lcinterestcost--> : ', data.lcinterestcost);
                console.log('data.lcusanceperiod--> : ', data.lcusanceperiod);
                const sumforlcinterest = parseFloat(totalvalue + data.rfidCostINR + data.moduleOverheadINR + data.moduleFinanceINR + data.cellBOMINR + data.cellOverheadINR + data.cellFinanceINR + moduleWarrantyInsuranceCostINR + bGradeModuleLossINR + abgCostINR + pbgCostINR + data.outboundlogisticsINR + data.exportfreightchargesINR);
                var lcinterestcostINR = (
                    (parseFloat(sumforlcinterest)) *
                    (parseFloat(1 - (data.paymentterm / 100))) *
                    parseFloat(data.lcinterestcost / 100) / 365 *
                    parseFloat(data.lcusanceperiod)
                );
                lcinterestcostINR = Number(lcinterestcostINR.toFixed(2));
                const lcinterestcostCent = (lcinterestcostINR * 100 / data.rbi).toFixed(2);
                console.log('totalvalue:', totalvalue);
                console.log('rfidCostINR:', data.rfidCostINR);
                console.log('moduleOverheadINR:', data.moduleOverheadINR);
                console.log('moduleFinanceINR:', data.moduleFinanceINR);
                console.log('cellBOMINR:', data.cellBOMINR);
                console.log('cellOverheadINR:', data.cellOverheadINR);
                console.log('cellFinanceINR:', data.cellFinanceINR);
                console.log('moduleWarrantyInsuranceCostINR:', moduleWarrantyInsuranceCostINR);
                console.log('bGradeModuleLossINR:', bGradeModuleLossINR);
                console.log('abgCostINR:', abgCostINR);
                console.log('pbgCostINR:', pbgCostINR);
                console.log('outboundlogistics:', data.outboundlogisticsINR);
                console.log('exportfreightchargesINR:', data.exportfreightchargesINR);
                console.log('transitinsurancecostINR:', transitinsurancecostINR);
                console.log('lcinterestcostINR:', lcinterestcostINR);


                //const totalforebitda = (parseFloat(totalvalue) + parseFloat(data.rfidCostINR) + parseFloat(data.moduleOverheadINR) + parseFloat(data.moduleFinanceINR) + parseFloat(data.cellBOMINR) + parseFloat(data.cellOverheadINR) + parseFloat(data.cellFinanceINR) + parseFloat(moduleWarrantyInsuranceCostINR) + parseFloat(bGradeModuleLossINR) + parseFloat(abgCostINR) + parseFloat(pbgCostINR) + parseFloat(data.outboundlogistics) + parseFloat(data.exportfreightchargesINR) + parseFloat(transitinsurancecostINR) + parseFloat(lcinterestcostINR));
                // totalforebitda = totalforebitda.toFixed(2);
                const totalforebitda =
                    totalvalue +
                    data.rfidCostINR +
                    data.moduleOverheadINR +
                    data.moduleFinanceINR +
                    data.cellBOMINR +
                    data.cellOverheadINR +
                    data.cellFinanceINR +
                    moduleWarrantyInsuranceCostINR +
                    bGradeModuleLossINR +
                    abgCostINR +
                    pbgCostINR +
                    data.outboundlogisticsINR +
                    data.exportfreightchargesINR +
                    transitinsurancecostINR +
                    lcinterestcostINR;


                console.log('totalforebitda--> : ', totalforebitda);
                console.log('data.ebitda--> : ', data.ebitda);
                const ebitdaINR = Number(((data.ebitda / 100) * (totalforebitda - data.moduleFinanceINR)).toFixed(2));
                const ebitdaCent = (ebitdaINR * 100 / data.rbi).toFixed(2);
                const pbtINR = Number((ebitdaINR - data.moduleFinanceINR).toFixed(2));
                const pbtCent = (pbtINR * 100 / data.rbi).toFixed(2);
                console.log('pbtINR--> : ', pbtINR);

                const finalpriceINR = (totalforebitda + parseFloat(pbtINR)).toFixed(2);
                const finalpriceCent = (finalpriceINR * 100 / data.rbi).toFixed(2);
                console.log('data.rfidCostINR : ', data.rfidCostINR);
                console.log('data.moduleOverheadINR : ', data.moduleOverheadINR);
                console.log('outboundlogisticsINR--> : ', data.outboundlogisticsINR);
                this.costRows = [
                    { label: 'RFID reader cost', col2: data.rfidCostINR, col3: data.rfidCostCents },
                    { label: 'Module Overhead cost (cents/Wp)', col2: data.moduleOverheadINR, col3: data.moduleOverheadCents },
                    { label: 'Module Finance Cost(Cents/Wp)', col2: data.moduleFinanceINR, col3: data.moduleFinanceCents },
                    { label: 'Cell BOM Cost (Cents/Wp)', col2: data.cellBOMINR, col3: data.cellBOMCents },
                    { label: 'Cell - Overhead Cost (Cents/Wp)', col2: data.cellOverheadINR, col3: data.cellOverheadCents },
                    { label: 'Cell- Finance Cost(Cents/Wp)', col2: data.cellFinanceINR, col3: data.cellFinanceCents },
                    { label: 'Module Warranty insurance Cost', col2: moduleWarrantyInsuranceCostINR, col3: moduleWarrantyInsuranceCostCent },
                    { label: 'B-Grade Module Loss', col2: bGradeModuleLossINR, col3: bGradeModuleLossCent },
                    { label: 'ABG Cost', col2: abgCostINR, col3: abgCostCent },
                    { label: 'PBG Cost', col2: pbgCostINR, col3: pbgCostCent },
                    { label: 'outbound logistics', col2: data.outboundlogisticsINR, col3: data.outboundlogisticsCent },
                    { label: 'Export Freight Charges', col2: data.exportfreightchargesINR, col3: data.exportfreightchargesCent },
                    { label: 'Transit Insurance Cost', col2: transitinsurancecostINR, col3: transitinsurancecostCent },
                    { label: 'LC Interest Cost', col2: lcinterestcostINR, col3: lcinterestcostCent },
                    { label: 'EBITDA Margin', col2: ebitdaINR, col3: ebitdaCent },
                    { label: 'PBT Margin', col2: pbtINR, col3: pbtCent },
                    { label: 'FINAL Wp PRICE', col2: finalpriceINR, col3: finalpriceCent }
                ];
            })
            .catch(error => {
                console.error('Error fetching cost data-->', JSON.stringify(error));
                if (error && error.body && error.body.message) {
                    console.error('Detailed Error:', error.body.message);
                } else if (error.message) {
                    console.error('Error message:', error.message);
                } else {
                    console.error('Unknown error structure:', error);
                }
            });


    }

    get isDisabled() {
        return !this.isEditable;
    }

    @wire(getRawMaterialData, {
        opportunityId: '$recordId',
        pricingType: '$pricingType',
        countrySource: '$countrySource'
    })
    wiredRawMaterials({ data, error }) {
        if (data) {
            console.log('Data--> : ', data);
            this.allRawMaterialVariants = data;
            const variableMaterialsforapex = data;
            console.log('all raw--> : ', JSON.stringify(this.allRawMaterialVariants));
            this.rawMaterialData = data
                .filter(item => item.netBoQData !== 0 && item.netBoQData !== null && item.netBoQData !== undefined && item.isDefaultSkip == false)
                .map((item, index) => ({
                    ...item,
                    id: `row-${index}`,
                    rawMaterialName: item.rawMaterialName || '',
                    uom: item.uom || '',
                    requiredQuantityPerUnit: item.netBoQData || 0,
                    actualPriceUsed: item.actualPriceUsed || 0,
                    rawCostUSD: item.rawCostUSD || 0,
                    rawCostINR: item.rawCostINR || 0,
                    logisticsCalculation: item.logisticsCalculation || 0,
                    insurancePercentage: item.insurancePercentage || 0,
                    DutyModule: item.totalCostWithMargin || 0,
                    Ddp: item.totalCostWithMarginAdded || 0,
                    InrWp: item.rawCostINRPerWattage || 0,
                    centsDp: item.rawCostUSDPerWattage || 0,
                    isVariable: item.isVariable || false,
                    isDefaultSkip: item.isDefaultSkip || false,
                    defaultVariantGroupId: item.defaultVariantGroupId || '',
                    variantOptions: [],
                    rawMaterialId: item.rawMaterialId || ''
                }));

            //const storedVariantId = localStorage.getItem('selectedVariantId');
            //const storedData = JSON.parse(localStorage.getItem('variantSelection'));

            // const storedVariantId = storedData?.selectedVariantId || false;
            //const oppId = storedData?.oppId || false;

            const variableMaterials = variableMaterialsforapex.filter(variant => variant.isVariable == true && variant.isDefaultSkip == false).map(variant => variant.rawMaterialId);
            console.log('variableMaterials--> : ', JSON.stringify(variableMaterials));

            checkVariables({ oppId: this.recordId, rawMaterialIds: variableMaterials }).then(result => {
                console.log('fetch changed variables result--> : ', JSON.stringify(result));
                const variablesfromapex = result;
                this.storeVariableIds = result;
                console.log('storeVariableIds--> : ', JSON.stringify(this.storeVariableIds));
                console.log('variablesfromapex--> : ', variablesfromapex);
                this.storeVariableIds.forEach(material => {
                    console.log('changed material ids --> : ', material);
                });
            

            //console.log('storedVariantId local--> : ', storedVariantId);
            console.log('storeVariableIds for loop--> : ', this.storeVariableIds);
            console.log('storeVariableIds for loop stringify--> : ', JSON.stringify(this.storeVariableIds));
            this.storeVariableIds.forEach(storedVariantId => {
                console.log('storedVariantId material ids --> : ', storedVariantId);

                if (storedVariantId != null) {
                    const selectedVariant = this.allRawMaterialVariants.find(variant => variant.rawMaterialId == storedVariantId);
                    if (selectedVariant) {
                        const materialCheck = this.rawMaterialData.find(m => m.rawMaterialId == selectedVariant.rawMaterialId);
                        console.log('materialCheck--> : ', materialCheck);
                        if (!materialCheck) {
                            console.log('OUInside materialCheck : ',);
                            this.rawMaterialData = this.rawMaterialData.map(material => {
                                if (material.rawMaterialId === selectedVariant.defaultVariantGroupId) {
                                    return Object.assign({}, material, {
                                        rawMaterialName: selectedVariant.rawMaterialName || '',
                                        uom: selectedVariant.uom || '',
                                        requiredQuantityPerUnit: selectedVariant.netBoQData || 0,
                                        actualPriceUsed: selectedVariant.actualPriceUsed || 0,
                                        rawCostUSD: selectedVariant.rawCostUSD || 0,
                                        rawCostINR: selectedVariant.rawCostINR || 0,
                                        logisticsCalculation: selectedVariant.logisticsCalculation || 0,
                                        insurancePercentage: selectedVariant.insurancePercentage || 0,
                                        DutyModule: selectedVariant.totalCostWithMargin || 0,
                                        Ddp: selectedVariant.totalCostWithMarginAdded || 0,
                                        InrWp: selectedVariant.rawCostINRPerWattage || 0,
                                        centsDp: selectedVariant.rawCostUSDPerWattage || 0,
                                        isVariable: selectedVariant.isVariable || false,
                                        isDefaultSkip: selectedVariant.isDefaultSkip || false,
                                        defaultVariantGroupId: selectedVariant.defaultVariantGroupId || '',
                                        selectedVariantId: storedVariantId
                                    });
                                }
                                return material;
                            });

                            // this.formatData();
                        }
                    }
                }
            });



            this.rawMaterialData.forEach(material => {
                if (material.isVariable) {
                    console.log('Variable material name--> : ', material.rawMaterialName);
                    console.log('Variable material id--> : ', material.rawMaterialId);
                    console.log('--- All Raw Material Variants ---');
                    this.allRawMaterialVariants.forEach(variant => {
                        console.log(
                            `Name: ${variant.rawMaterialName}, ` +
                            `isVariable: ${variant.isVariable}, ` +
                            `defaultVariantGroupId: ${variant.defaultVariantGroupId}`
                        );
                    });
                    this.rawMaterialData.forEach(variant => {
                        console.log(
                            `Name: ${variant.rawMaterialName}, ` +
                            `isVariable: ${variant.isVariable}, ` +
                            `defaultVariantGroupId: ${variant.defaultVariantGroupId}`
                        );
                    });
                    console.log('---------------------------------');
                    const matchingVariants = this.allRawMaterialVariants
                        .filter(variant =>
                            variant.isVariable == true &&
                            (variant.defaultVariantGroupId == material.rawMaterialId ||
                                variant.rawMaterialId == material.defaultVariantGroupId)
                        )
                        .map(variant => ({
                            label: variant.rawMaterialName,
                            value: variant.rawMaterialId
                        }));
                    console.log('matchingVariants--> : ', matchingVariants);

                    const selfOption = {
                        label: material.rawMaterialName,
                        value: material.rawMaterialId
                    };
                    console.log('material.variantOptions--> : ', material.variantOptions);
                    const isSelfIncluded = matchingVariants.some(opt => opt.value === selfOption.value);

                    material.variantOptions = isSelfIncluded
                        ? matchingVariants
                        : [selfOption, ...matchingVariants];
                    material.selectedVariantId ??= material.rawMaterialId;
                    console.log(`Variants for ${material.rawMaterialName}: `, JSON.stringify(material.variantOptions));
                }
            });

            console.log('rawMaterials-->', JSON.stringify(this.rawMaterialData));

            this.formatData();
            }).catch(error => {
                console.log('fetch changed variables error--> : ', error);
            })
        } else if (error) {
            console.error('Error loading data:', error);
            this.rawMaterialData = [];
            this.formattedData = [];
        }
    }
    handleVariantChange(event) {
        const selectedId = event.detail.value;
        const rowId = event.target.dataset.id;
        console.log('Variant changed --> Selected ID:', selectedId, 'for row:', rowId);

        //localStorage.setItem('selectedVariantId', selectedId);
        //const dataToStore = {
        //  selectedVariantId: selectedId,
        //  oppId: this.recordId
        //};

        // localStorage.setItem('variantSelection', JSON.stringify(dataToStore));


        const selectedVariant = this.allRawMaterialVariants.find(
            variant => variant.rawMaterialId == selectedId
        );

        if (selectedVariant) {
            const materialToUpdate = this.rawMaterialData.find(m => m.id === rowId);
            console.log('materialToUpdate--> : ', materialToUpdate);

            if (materialToUpdate) {
                console.log('materialToUpdate.rawMaterialId--> : ', materialToUpdate.rawMaterialId);
                console.log('selectedId--> : ', selectedId);
                createVariables({ oppId: this.recordId, oldRM: materialToUpdate.rawMaterialId, newRM: selectedId }).then(result => {
                    console.log('variable creation result--> : ', result);
                }).catch(error => {
                    console.log('variable creation error : ', error);
                })
                materialToUpdate.rawMaterialName = selectedVariant.rawMaterialName || '';
                materialToUpdate.uom = selectedVariant.uom || '';
                materialToUpdate.requiredQuantityPerUnit = selectedVariant.netBoQData || 0;
                materialToUpdate.actualPriceUsed = selectedVariant.actualPriceUsed || 0;
                materialToUpdate.rawCostUSD = selectedVariant.rawCostUSD || 0;
                materialToUpdate.rawCostINR = selectedVariant.rawCostINR || 0;
                materialToUpdate.logisticsCalculation = selectedVariant.logisticsCalculation || 0;
                materialToUpdate.insurancePercentage = selectedVariant.insurancePercentage || 0;
                materialToUpdate.DutyModule = selectedVariant.totalCostWithMargin || 0;
                materialToUpdate.Ddp = selectedVariant.totalCostWithMarginAdded || 0;
                materialToUpdate.InrWp = selectedVariant.rawCostINRPerWattage || 0;
                materialToUpdate.centsDp = selectedVariant.rawCostUSDPerWattage || 0;
                materialToUpdate.selectedVariantId = selectedId;

                console.log(`Updated material row ${rowId} with selected variant`, selectedVariant);

                this.formatData();
            }
        } else {
            console.warn('Selected variant not found in allRawMaterialVariants');
        }
    }


    costRows = [
        { label: 'RFID reader cost', col2: '', col3: '' },
        { label: 'Module Overhead cost (cents/Wp)-DOE,OOE,EBE,Warranty prov', col2: '', col3: '' },
        { label: 'Module Finance Cost(Cents/Wp)-DEPT,Int TL & WC, Hedge', col2: '', col3: '' },
        { label: 'Cell BOM Cost (Cents/Wp)', col2: '', col3: '' },
        { label: 'Cell - Overhead Cost (Cents/Wp)- DOE,OOE,EBE,Warranty prov', col2: '', col3: '' },
        { label: 'Cell- Finance Cost(Cents/Wp)- DEPT, Int TL &WC,Hedge', col2: '', col3: '' },
        { label: 'Module Warranty insurance Cost', col2: '', col3: '' },
        { label: 'B-Grade Module Loss', col2: '', col3: '' },
        { label: 'ABG Cost', col2: '', col3: '' },
        { label: 'PBG Cost', col2: '', col3: '' },
        { label: 'outbound logistics', col2: '', col3: '' },
        { label: 'Export Freight Charges', col2: '', col3: '' },
        { label: 'Transit Insurance Cost', col2: '', col3: '' },
        { label: 'LC Interest Cost', col2: '', col3: '' },
        { label: 'EBITDA Margin', col2: '', col3: '' },
        { label: 'PBT Margin', col2: '', col3: '' },
        { label: 'FINAL Wp PRICE', col2: '', col3: '' }
    ];

    handleCountryChange(event) {
        this.countrySource = event.detail.value;
    }

    handlePricingChange(event) {
        this.pricingType = event.detail.value;
    }

    formatData() {
        let sum = 0;
        let centsum = 0;

        this.formattedData = this.rawMaterialData.map(item => {
            const formattedInrWp = this.formatDecimal(item.InrWp);
            sum += parseFloat(formattedInrWp) || 0;

            const formattedCentsDp = this.formatDecimal(item.centsDp)
            centsum += parseFloat(formattedCentsDp) || 0;

            return {
                ...item,
                formattedRawCostUSD: this.formatCurrency(item.rawCostUSD, 'USD'),
                formattedRawCostINR: this.formatDecimal(item.rawCostINR),
                formattedLogistics: this.formatDecimal(item.logisticsCalculation),
                formattedInsurance: this.formatDecimal(item.insurancePercentage),
                formattedDuty: this.formatDecimal(item.DutyModule),
                formattedDdp: this.formatDecimal(item.Ddp),
                formattedInrWp,
                formattedCentsDp
            };
        });

        this.totalInrWp = this.formatDecimal(sum);
        this.totalCentWp = this.formatDecimal(centsum);
        this.fetchAdminInputs();
    }



    formatDecimal(value) {
        if (value === null || value === undefined) return '0.00';
        const num = typeof value === 'string' ? parseFloat(value) : value;
        return num.toFixed(2);
    }

    formatCurrency(value, currencyCode) {
        if (value === null || value === undefined) return '0.00';
        const num = typeof value === 'string' ? parseFloat(value) : value;
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: currencyCode,
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        }).format(num);
    }
  }