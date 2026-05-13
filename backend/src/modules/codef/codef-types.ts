export type CodefLoginType = '0' | '1';

export interface CodefResponse<T> {
  result?: {
    code?: string;
    message?: string;
    extraMessage?: string;
  };
  data?: T;
}

export interface CodefConnectedAccount {
  countryCode?: string;
  businessType?: string;
  clientType?: string;
  organization?: string;
  organizationCode?: string;
  loginType?: string;
  code?: string;
  message?: string;
}

export interface CodefAccountCreateData {
  connectedId: string;
  successList?: CodefConnectedAccount[];
  errorList?: CodefConnectedAccount[];
}

export interface CodefCardListItem {
  resCardNo?: string;
  cardName?: string;
  organization?: string;
  organizationName?: string;
}

export interface CodefCardListData {
  cardList?: CodefCardListItem[];
}

export interface CodefApprovalItem {
  approvalNo?: string;
  approvalDate?: string;
  approvalTime?: string;
  approvalDay?: string;
  approvalAmount?: string | number;
  approvalStatus?: string;
  merchantName?: string;
  merchantRegNo?: string;
  merchantAddr?: string;
  cardName?: string;
  cardNo?: string;
  resCardNo?: string;
  paymentType?: string;
  installmentMonths?: string | number;
  originAmount?: string | number;
  originCurrency?: string;
  billingAmount?: string | number;
  billingCurrency?: string;
}

export interface CodefApprovalListData {
  resCount?: string | number;
  resApprovalList?: CodefApprovalItem[];
  approvalList?: CodefApprovalItem[];
  nextPageNo?: string | number;
  hasNext?: boolean;
}
