import json
import xml.etree.ElementTree as ET
import logging
from xml.etree.ElementTree import QName

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")

# TEI Namespace
TEI_NS = "http://www.tei-c.org/ns/1.0"
NSMAP = {"tei": TEI_NS}

#  namespace to avoid 'ns0' prefixes in output XML
ET.register_namespace("", TEI_NS)

def update_tei_dates(json_file_path, xml_file_path):
    """Transfers exact dates and bibliographic note information from a Zotero JSON file to a TEI XML file."""
    
    # Load JSON 
    try:
        with open(json_file_path, "r", encoding="utf-8") as f:
            json_data = json.load(f)
    except (FileNotFoundError, json.JSONDecodeError) as e:
        logging.error(f"Failed to read JSON file '{json_file_path}': {e}")
        return

    # Load and parse XML file
    try:
        tree = ET.parse(xml_file_path)
        root = tree.getroot()
    except (FileNotFoundError, ET.ParseError) as e:
        logging.error(f"Failed to parse XML file '{xml_file_path}': {e}")
        return

    logging.info("Starting date and note transfer process...")
    updated = False  # Track if any changes were made

    for item in json_data:
        zotero_id_json = item.get("id", "").split("/")[-1]  # Extract Zotero ID
        date_parts = item.get("issued", {}).get("date-parts", [[]])[0]  # Extract date information
        note_text = item.get("note")  # Extract bibliographic note

        # Convert extracted date parts into a formatted string (YYYY-MM-DD)
        if isinstance(date_parts, list):
            try:
                date_parts_int = [int(part) for part in date_parts]
                correct_date = f"{date_parts_int[0]}"
                if len(date_parts_int) > 1:
                    correct_date += f"-{str(date_parts_int[1]).zfill(2)}"
                if len(date_parts_int) > 2:
                    correct_date += f"-{str(date_parts_int[2]).zfill(2)}"
            except ValueError:
                correct_date = None
        else:
            correct_date = None

        logging.info(f"Processing Zotero ID: {zotero_id_json}")
        logging.info(f"Extracted date from JSON: {correct_date}")

        if not zotero_id_json:
            logging.warning("Skipping entry with missing Zotero ID.")
            continue

        # Find the corresponding <biblStruct> entry in the XML file
        matching_bibl_struct = None
        for bibl_struct in root.findall(".//tei:biblStruct", namespaces=NSMAP):
            corresp_attr = bibl_struct.get("corresp")
            if corresp_attr and corresp_attr.endswith(zotero_id_json):
                matching_bibl_struct = bibl_struct
                break

        if not matching_bibl_struct: # Outdated, but works (for now..)
            logging.warning(f"No matching XML entry found for Zotero ID '{zotero_id_json}'.")
            continue

        # Locate the <imprint> element inside the matching <biblStruct>
        imprint_element = matching_bibl_struct.find(".//tei:imprint", namespaces=NSMAP)
        if imprint_element is None:
            logging.warning(f"No <imprint> found for Zotero ID '{zotero_id_json}'. Skipping...")
            continue

        logging.info("Imprint element found.")

        # Locate or create a <date> element inside <imprint>
        date_element = imprint_element.find("tei:date", namespaces=NSMAP)
        if date_element is not None:
            logging.info(f"Existing date element found: {date_element.text}")
            if correct_date and date_element.text != correct_date:
                date_element.text = correct_date
                updated = True
                logging.info(f"Updated date for Zotero ID '{zotero_id_json}' to '{correct_date}'")
            else:
                logging.info("Date is already up-to-date.")
        elif correct_date:
            new_date_element = ET.Element(QName(TEI_NS, "date"))
            new_date_element.text = correct_date
            imprint_element.append(new_date_element)
            updated = True
            logging.info(f"Created new <date> element for Zotero ID '{zotero_id_json}' with date '{correct_date}'")

        # Locate or create a <note type="bibliographic"> element
        if note_text:
            note_element = matching_bibl_struct.find(".//tei:note[@type='bibliographic']", namespaces=NSMAP)
            if note_element is not None:
                if note_element.text != note_text:
                    note_element.text = note_text
                    updated = True
                    logging.info(f"Updated <note type='bibliographic'> for Zotero ID '{zotero_id_json}'")
                else:
                    logging.info("Note is already up-to-date.")
            else:
                new_note_element = ET.Element(QName(TEI_NS, "note"))
                new_note_element.text = note_text
                new_note_element.set("type", "bibliographic")
                matching_bibl_struct.append(new_note_element)
                updated = True
                logging.info(f"Added <note type='bibliographic'> for Zotero ID '{zotero_id_json}'")

    # Save the XML file only if changes were made
    if updated:
        try:
            tree.write(xml_file_path, encoding="utf-8", xml_declaration=True)
            logging.info(f"Successfully updated XML file: {xml_file_path}")
        except Exception as e:
            logging.error(f"Failed to write updated XML: {e}")
    else:
        logging.info("No updates were necessary.")

if __name__ == "__main__":
    json_file = "sanders_daniel_bibliography_new.json"
    xml_file = "sanders_daniel_bibliography_new.xml"
    update_tei_dates(json_file, xml_file)