package com.portside.trading.domain;

/** Every stock quantity change is one of these; the signed qty on the movement carries direction. */
public enum MovementType { RECEIPT, SALE, SALE_RETURN, DAMAGED, MISSING, CORRECTION, OTHER_ADJUSTMENT }
