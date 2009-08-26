
def template_builder(*lines_of_elements)
  lines_of_elements.collect { |l| l.join("\t")}.join("\r\n")
end