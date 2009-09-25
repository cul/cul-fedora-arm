require 'base64'

METADATA_MODS_TEST = <<METADATA
<mods xmlns="http://www.loc.gov/mods/v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-2.xsd">
<identifier type="local">test.identifier.1</identifier>
<titleInfo displayLabel="Supplied title">
<title>%s</title>
</titleInfo>
</mods>
METADATA
# >>

METADATA_DC_TEST = <<METADATA
<oai_dc:dc xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/" >
<dc:title>Test Input Data</dc:title>
<dc:creator>BATCH</dc:creator>
<dc:type>Text</dc:type>
<dc:format>text/xml</dc:format>
<dc:publisher>Columbia University Libraries</dc:publisher>
<dc:identifier>test.identifier.1</dc:identifier>
<dc:source>%s</dc:source>
</oai_dc:dc>
METADATA
# >>

NEXT_PIDS_SOAP_MESSAGE =  <<NEXT_PID
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
<soap:Body>
<getNextPID xmlns="http://www.fedora.info/definitions/1/0/api/">
<numPIDs>13</numPIDs>
<pidNamespace>test</pidNamespace>
</getNextPID>
</soap:Body>
</soap:Envelope>
NEXT_PID
# >>

