import sys
import pkgutil

print("Python Executable:", sys.executable)
try:
    import langchain
    print("LangChain file:", langchain.__file__)
    print("LangChain dir:", dir(langchain))
    
    # Check if community has chains
    import langchain_community
    print("LangChain Community found.")
    
    try:
        from langchain.chains import RetrievalQA
        print("Success: RetrievalQA found in langchain.chains")
    except ImportError:
        print("Failed: langchain.chains")
        
    try:
        from langchain_community.chains import RetrievalQA
        print("Success: RetrievalQA found in langchain_community.chains")
    except ImportError:
        print("Failed: langchain_community.chains")

except ImportError as e:
    print("Import Error:", e)
except Exception as e:
    print("Error:", e)
