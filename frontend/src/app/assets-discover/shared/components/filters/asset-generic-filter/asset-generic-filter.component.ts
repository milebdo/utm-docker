import {Component, EventEmitter, Input, OnInit, Output} from '@angular/core';
import {ElasticFilterType} from '../../../../../shared/types/filter/elastic-filter.type';
import {AssetFiltersBehavior} from '../../../behavior/asset-filters.behavior';
import {AssetReloadFilterBehavior} from '../../../behavior/asset-reload-filter-behavior.service';
import {STATICS_FILTERS} from '../../../const/filter-const';
import {AssetFieldFilterEnum} from '../../../enums/asset-field-filter.enum';
import {AssetMapFilterFieldEnum} from '../../../enums/asset-map-filter-field.enum';
import {UtmNetScanService} from '../../../services/utm-net-scan.service';
import {AssetFilterType} from '../../../types/asset-filter.type';
import {CollectorFieldFilterEnum} from "../../../enums/collector-field-filter.enum";
import {
  AlertGenericFilerSort
} from "../../../../../shared/components/utm/util/generic-filer-sort/generic-filer-sort.component";

@Component({
  selector: 'app-asset-generic-filter',
  templateUrl: './asset-generic-filter.component.html',
  styleUrls: ['./asset-generic-filter.component.scss']
})
export class AssetGenericFilterComponent implements OnInit {
  @Input() fieldFilter: ElasticFilterType;
  @Output() filterGenericChange = new EventEmitter<{ prop: AssetFieldFilterEnum | CollectorFieldFilterEnum, values: string[] }>();
  @Input() forGroups = false;
  fieldValues: Array<[string, number]> = [];
  loading = true;
  selected = [];
  loadingMore = false;
  searching = false;
  requestParams: any;
  sort: { orderByCount: boolean, sortAsc: boolean } = {orderByCount: true, sortAsc: false};

  constructor(private utmNetScanService: UtmNetScanService,
              private assetTypeChangeBehavior: AssetReloadFilterBehavior,
              private assetFiltersBehavior: AssetFiltersBehavior) {
  }

  ngOnInit() {
    this.requestParams = {page: 0, prop: this.fieldFilter.field, size: 6, forGroups: this.forGroups};
    this.getPropertyValues();
    this.assetFiltersBehavior.$assetFilter.subscribe(filters => {
      if (filters) {
        this.setValueOfFilter(filters);
      }
    });
    /**
     * Update type values filter on type is applied to asset
     */
    this.assetTypeChangeBehavior.$assetReloadFilter.subscribe(change => {
      if (change && this.fieldFilter.field === change) {
        this.requestParams.page = 0;
        this.fieldValues = [];
        this.loading = true;
        this.getPropertyValues();
      }
    });
  }

  getPropertyValues() {
    this.utmNetScanService.getFieldValues(this.requestParams).subscribe(response => {
      this.fieldValues = this.fieldValues.concat(response.body);
      this.loading = false;
      this.searching = false;
      this.loadingMore = false;
    });
  }

  onSortValuesChange($event: { orderByCount: boolean; sortAsc: boolean }) {
    this.sort = $event;
    this.getPropertyValues();
  }

  onScroll() {
    this.requestParams.page += 1;
    this.loadingMore = true;
    this.getPropertyValues();
  }

  selectValue(value: string) {
    const index = this.selected.findIndex(val => val === value);
    if (index === -1) {
      this.selected.push(value);
    } else {
      this.selected.splice(index, 1);
    }

    this.filterGenericChange.emit({prop: AssetFieldFilterEnum[this.fieldFilter.field] ?
        AssetFieldFilterEnum[this.fieldFilter.field] : CollectorFieldFilterEnum[this.fieldFilter.field], values: this.selected});

  }

  searchInValues($event: string) {
    this.requestParams.value = $event;
    this.requestParams.page = 0;
    this.searching = true;
    this.fieldValues = [];
    this.getPropertyValues();
  }

  setValueOfFilter(filters: AssetFilterType) {
    console.log('setValueOfFilter');
    for (const key of Object.keys(filters)) {
      const filterKey = AssetFieldFilterEnum[this.fieldFilter.field] ?
        AssetFieldFilterEnum[this.fieldFilter.field] : CollectorFieldFilterEnum[this.fieldFilter.field];
      if (!STATICS_FILTERS.includes(key)
        && key === AssetMapFilterFieldEnum[filterKey]) {
        this.selected = filters[key] === null ? [] : filters[key];
      }
    }
  }

}
