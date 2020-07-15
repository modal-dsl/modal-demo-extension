tableextension 50131 "SEM Seminar Reg. Line Ext." extends "SEM Sem. Reg. Line"
{
    fields
    {
        modify("Bill-to Customer No.")
        {
            trigger OnBeforeValidate()
            var
                TempSemRegLine: Record "SEM Sem. Reg. Line" temporary;
                Cust: Record Customer;
            begin
                if "Bill-to Customer No." = xRec."Bill-to Customer No." then
                    EXIT;

                if "Bill-to Customer No." <> xRec."Bill-to Customer No." then begin
                    TestStatusPlanning();
                    TestField(Registered, false);
                    TestField("Confirmation Date", 0D);
                end;

                TempSemRegLine := Rec;

                if xRec."Bill-to Customer No." <> '' then begin
                    InitRecord;
                    "Bill-to Customer No." := TempSemRegLine."Bill-to Customer No.";
                end;

                if "Bill-to Customer No." <> '' then begin
                    Cust.Get("Bill-to Customer No.");
                    Cust.TestField(Blocked, Cust.Blocked::" ");
                    "Gen. Bus. Posting Group" := Cust."Gen. Bus. Posting Group";
                end;
            end;
        }
        modify("Participant Contact No.")
        {
            trigger OnBeforeValidate()
            var
                ContBusinessRelation: Record "Contact Business Relation";
                Cont: Record Contact;
                Cust: Record Customer;
                TempSemRegLine: Record "SEM Sem. Reg. Line" temporary;
                Confirmed: Boolean;
            begin
                if "Participant Contact No." = xRec."Participant Contact No." then
                    exit;

                if ("Participant Contact No." <> xRec."Participant Contact No.") and (xRec."Participant Contact No." <> '') then begin
                    if GetHideValidationDialog or not GuiAllowed then
                        Confirmed := true
                    else
                        Confirmed := Confirm(ConfirmChangeQst, false, FieldCaption("Participant Contact No."));
                    if not Confirmed then begin
                        "Participant Contact No." := xRec."Participant Contact No.";
                        exit;
                    end;
                end;

                if "Participant Contact No." = '' then
                    exit;

                TempSemRegLine := Rec;

                InitRecord();
                "Bill-to Customer No." := TempSemRegLine."Bill-to Customer No.";
                "Participant Contact No." := TempSemRegLine."Participant Contact No.";
                "Gen. Bus. Posting Group" := TempSemRegLine."Gen. Bus. Posting Group";

                CalcFields("Participant Name");

                if "Bill-to Customer No." = '' then begin
                    ContBusinessRelation.SETRANGE("Contact No.", Cont."Company No.");
                    ContBusinessRelation.SETRANGE("Link to Table", ContBusinessRelation."Link to Table"::Customer);
                    if ContBusinessRelation.FINDFIRST then begin
                        Cust.GET(ContBusinessRelation."No.");
                        if Cust.Blocked = Cust.Blocked::" " then begin
                            "Gen. Bus. Posting Group" := Cust."Gen. Bus. Posting Group";
                            "Bill-to Customer No." := Cust."No.";
                        end;
                    end;
                end;
            end;

            trigger OnAfterValidate()
            begin
                if "Participant Contact No." <> xRec."Participant Contact No." then
                    CalcFields("Participant Name");
            end;
        }
        modify("Seminar Price")
        {
            trigger OnBeforeValidate()
            begin
                SeminarExtMgt.CheckMinValue(RecordId.GetRecord().Field(FieldNo("Seminar Price")), "Seminar Price", 0);
                Validate("Line Discount %");
            end;
        }
        modify("Line Discount %")
        {
            trigger OnBeforeValidate()
            begin
                TestStatusPlanning();
                "Line Discount Amount (LCY)" := Round("Seminar Price" * "Line Discount %" / 100);
                UpdateAmounts();
            end;
        }
        modify("Line Discount Amount (LCY)")
        {
            trigger OnBeforeValidate()
            var
                myInt: Integer;
            begin
                TestStatusPlanning();
                if xRec."Line Discount Amount (LCY)" <> "Line Discount Amount (LCY)" then
                    UpdateLineDiscPct();
                UpdateAmounts();
            end;
        }
        modify("Line Amount (LCY)")
        {
            trigger OnBeforeValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateLineAmount(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                TestStatusPlanning();
                "Line Amount (LCY)" := Round("Line Amount (LCY)");
                Validate(
                  "Line Discount Amount (LCY)", "Seminar Price" - "Line Amount (LCY)");
            end;
        }
        field(50130; "Participant Name"; Text[100])
        {
            Caption = 'Participant Name';
            FieldClass = FlowField;
            Editable = false;
            CalcFormula = Lookup (Contact.Name where("No." = field("Participant Contact No.")));
        }
    }

    trigger OnBeforeDelete()
    var
        SemRegHeader: Record "SEM Sem. Reg. Header";
    begin
        SemRegHeader.Get("Document No.");
        SemRegHeader.TestField(Status, SemRegHeader.Status::Registration);
        TestField(Registered, false);
    end;

    var
        ConfirmChangeQst: Label 'Do you want to change %1?';
        SeminarExtMgt: Codeunit "SEM Seminar Extensions Mgt.";
        LineDiscountPctErr: Label 'The value in the %1 field must be between 0 and 100.';

    procedure UpdateAmounts()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateAmounts(Rec, xRec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        "Line Amount (LCY)" := "Seminar Price" - "Line Discount Amount (LCY)";

        OnAfterUpdateAmounts(Rec, xRec, CurrFieldNo);
    end;

    procedure UpdateLineDiscPct()
    var
        LineDiscountPct: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateLineDiscPct(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Seminar Price" <> 0 then begin
            LineDiscountPct := Round("Line Discount Amount (LCY)" / "Seminar Price" * 100, 0.00001);
            if not (LineDiscountPct in [0 .. 100]) then
                Error(LineDiscountPctErr, FieldCaption("Line Discount %"));
            "Line Discount %" := LineDiscountPct;
        end else
            "Line Discount %" := 0;

        OnAfterUpdateLineDiscPct(Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateLineDiscPct(var SemRegLine: Record "SEM Sem. Reg. Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateLineDiscPct(var SemRegLine: Record "SEM Sem. Reg. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAmounts(var SemRegLine: Record "SEM Sem. Reg. Line"; xSemRegLine: Record "SEM Sem. Reg. Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateAmounts(var SemRegLine: Record "SEM Sem. Reg. Line"; var xSemRegLine: Record "SEM Sem. Reg. Line"; CurrentFieldNo: Integer)
    begin
    end;


    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateLineAmount(var SemRegLine: Record "SEM Sem. Reg. Line"; xSemRegLine: Record "SEM Sem. Reg. Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

}
