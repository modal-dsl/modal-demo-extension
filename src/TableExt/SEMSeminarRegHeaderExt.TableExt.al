tableextension 50130 "SEM Seminar Reg. Header Ext." extends "SEM Sem. Reg. Header"
{
    fields
    {
        modify("Starting Date")
        {
            trigger OnBeforeValidate()
            begin
                TestStatusPlanning();
                TestNoPostedLines();

                if "Starting Date" < Today then
                    Message(PostingDateInPastMsg, FieldCaption("Starting Date"));
            end;
        }
        modify("Instructor Code")
        {
            trigger OnAfterValidate()
            begin
                if "Instructor Code" <> xRec."Instructor Code" then
                    CalcFields("Instructor Name");
            end;
        }
        modify("Minimum Participants")
        {
            trigger OnBeforeValidate()
            begin
                SeminarExtMgt.CheckMinValue(RecordId.GetRecord().Field(FieldNo("Minimum Participants")), "Minimum Participants", 0);
                SeminarExtMgt.CheckLessThan(
                    RecordId.GetRecord().Field(FieldNo("Minimum Participants")),
                    "Minimum Participants",
                    RecordId.GetRecord().Field(FieldNo("Maximum Participants")),
                    "Maximum Participants"
                );
            end;
        }
        modify("Maximum Participants")
        {
            trigger OnBeforeValidate()
            begin
                SeminarExtMgt.CheckMinValue(RecordId.GetRecord().Field(FieldNo("Maximum Participants")), "Maximum Participants", 0);
                SeminarExtMgt.CheckGreaterThan(
                    RecordId.GetRecord().Field(FieldNo("Maximum Participants")),
                    "Maximum Participants",
                    RecordId.GetRecord().Field(FieldNo("Minimum Participants")),
                    "Minimum Participants"
                );
            end;
        }
        modify("Seminar Price")
        {
            trigger OnBeforeValidate()
            var
                SemRegLine: Record "SEM Sem. Reg. Line";
            begin
                SeminarExtMgt.CheckMinValue(RecordId.GetRecord().Field(FieldNo("Seminar Price")), "Seminar Price", 0);

                TestStatusPlanning();
                SemRegLine.SetRange("Document No.", "No.");
                SemRegLine.SetRange(Registered, false);
                SemRegLine.SetFilter("Seminar Price", '<>%1', "Seminar Price");
                If not SemRegLine.IsEmpty then
                    IF Confirm(UpdateLinesQst) then begin
                        If SemRegLine.FindSet(true) then
                            repeat
                                SemRegLine.Validate("Seminar Price", "Seminar Price");
                                SemRegLine.Modify();
                            until SemRegLine.Next() = 0;
                        Modify();
                    end;
            end;
        }
        field(50130; "Instructor Name"; Text[50])
        {
            Caption = 'Instructor Name';
            FieldClass = FlowField;
            CalcFormula = Lookup ("SEM Instructor".Name where(Code = field("Instructor Code")));
            Editable = false;
        }
        field(50131; "No. of Participants"; Integer)
        {
            Caption = 'No. of Participants';
            FieldClass = FlowField;
            CalcFormula = count ("SEM Sem. Reg. Line" where("Document No." = field("No.")));
            Editable = false;
        }
    }

    trigger OnBeforeDelete()
    var
        SemRegLine: Record "SEM Sem. Reg. Line";
    begin
        if not (Status in [Status::Canceled, Status::Closed]) then
            FieldError(Status, StatusCanceledOrClosedErr);

        SemRegLine.SetRange("Document No.", "No.");
        SemRegLine.SetRange(Registered, false);
        if not SemRegLine.IsEmpty then begin
            SemRegLine.SetRange(Registered, true);
            if not SemRegLine.IsEmpty then
                Error(ExistingUnpostedLinesErr, TableCaption);
        end;
    end;

    var
        SeminarExtMgt: Codeunit "SEM Seminar Extensions Mgt.";
        PostingDateInPastMsg: Label 'The %1 is in the past.';
        ExistingPostedLinesErr: Label 'This action is not allowed because of existing posted lines.';
        UpdateLinesQst: Label 'Would you like to update the lines?';
        StatusCanceledOrClosedErr: Label 'must be ''Canceled'' or ''Closed''';
        ExistingUnpostedLinesErr: Label 'The %1 cannot be deleted because of at least one unposted Line.';

    local procedure TestNoPostedLines()
    var
        SemRegLine: Record "SEM Sem. Reg. Line";
    begin
        SemRegLine.SetRange("Document No.", "No.");
        SemRegLine.SetRange(Registered, true);
        if not (SemRegLine.IsEmpty) then
            Error(ExistingPostedLinesErr);
    end;

}
